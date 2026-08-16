/**
 * KodiBot tool registry (OpenAI function-calling).
 *
 * Each role gets a scoped set of tools. Executors ALWAYS derive identity from the
 * authenticated `user` object (from the JWT) — never from model-supplied arguments —
 * so the bot can only ever read the logged-in user's own data.
 *
 * A tool entry is: { definition, execute(args, user) -> any-serialisable }.
 *
 * This is the Phase 0 starter set (read-only). Drafting/report-download/maintenance-write
 * tools are added in later phases.
 */

const pool = require('../config/db');
const analyticsService = require('./analytics.service');
const reportService = require('./report.service');

const clampLimit = (value, def, max) => {
  const n = parseInt(value, 10);
  if (Number.isNaN(n) || n < 1) return def;
  return Math.min(n, max);
};

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

// Mirror the validation used by maintenance.controller.js.
const MAINT_CATEGORIES = ['electrical', 'structural', 'plumbing', 'other'];
const MAINT_PRIORITIES = ['low', 'medium', 'high', 'urgent', 'emergency'];
const MAINT_STATUSES = ['pending', 'in_progress', 'completed', 'cancelled'];
const normCategory = (v) =>
  MAINT_CATEGORIES.includes(String(v || '').toLowerCase()) ? String(v).toLowerCase() : 'other';
const normPriority = (v) =>
  MAINT_PRIORITIES.includes(String(v || '').toLowerCase()) ? String(v).toLowerCase() : 'medium';

// Resolve an optional reporting period from tool args into 'YYYY-MM-DD' strings.
// Defaults to "year-to-date" (Jan 1 of the current year through today) when the
// model does not supply valid dates.
const pad = (n) => String(n).padStart(2, '0');
const toDateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

function resolvePeriod(args) {
  const today = new Date();
  const defaultStart = toDateStr(new Date(today.getFullYear(), 0, 1));
  const defaultEnd = toDateStr(today);
  const start = args && ISO_DATE.test(args.start_date) ? args.start_date : defaultStart;
  const end = args && ISO_DATE.test(args.end_date) ? args.end_date : defaultEnd;
  return { start, end };
}

// {year, month} object form, used by the rent-collection report.
function ymFromDateStr(s) {
  const [year, month] = s.split('-').map((v) => parseInt(v, 10));
  return { year, month };
}

// Shared OpenAI parameter schema for an optional reporting period.
const PERIOD_PARAMS = {
  type: 'object',
  properties: {
    start_date: {
      type: 'string',
      description: 'Start of the period as YYYY-MM-DD. Optional; defaults to Jan 1 this year.',
    },
    end_date: {
      type: 'string',
      description: 'End of the period as YYYY-MM-DD. Optional; defaults to today.',
    },
  },
  additionalProperties: false,
};

// ---------------------------------------------------------------------------
// Landlord / agent tools
// ---------------------------------------------------------------------------

const portfolioOverview = {
  definition: {
    type: 'function',
    function: {
      name: 'get_portfolio_overview',
      description:
        'Get a high-level snapshot of the landlord\'s whole portfolio: number of ' +
        'properties and units, occupancy, this/last month income, pending & overdue ' +
        'invoices and amounts, and open/urgent maintenance counts.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await analyticsService.getLandlordOverview(user.id);
    return result.success ? result.data : { error: 'Could not load portfolio overview.' };
  },
};

const arrears = {
  definition: {
    type: 'function',
    function: {
      name: 'get_arrears',
      description:
        'List tenants who currently owe rent (pending or overdue invoices) across the ' +
        'landlord\'s properties, with tenant name, phone, property, unit, amount, due date ' +
        'and days overdue. Use for "who is behind on rent" type questions.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await reportService.generateArrearsReport(user.id);
    return result.success ? { arrears: result.data } : { error: 'Could not load arrears.' };
  },
};

const occupancy = {
  definition: {
    type: 'function',
    function: {
      name: 'get_occupancy',
      description:
        'Get occupancy per property: total units, occupied, vacant and occupancy rate. ' +
        'Use for vacancy and occupancy questions.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await reportService.generateOccupancyReport(user.id);
    return result.success ? { occupancy: result.data } : { error: 'Could not load occupancy.' };
  },
};

const incomeReport = {
  definition: {
    type: 'function',
    function: {
      name: 'get_income_report',
      description:
        'Income for a period: per property and overall, the amount expected (invoiced), ' +
        'collected (paid) and still pending. Use for "how much did I make/collect" questions.',
      parameters: PERIOD_PARAMS,
    },
  },
  async execute(args, user) {
    const { start, end } = resolvePeriod(args);
    const result = await reportService.generateIncomeReport(user.id, start, end);
    return result.success
      ? { period: { start, end }, ...result.data }
      : { error: 'Could not load income report.' };
  },
};

const rentCollectionReport = {
  definition: {
    type: 'function',
    function: {
      name: 'get_rent_collection_report',
      description:
        'Per-tenant rent collection over a period: invoice amount, status and amount paid by ' +
        'property, unit and month. Use for detailed "who paid what" breakdowns.',
      parameters: PERIOD_PARAMS,
    },
  },
  async execute(args, user) {
    const { start, end } = resolvePeriod(args);
    const result = await reportService.generateRentCollectionReport(
      ymFromDateStr(start),
      ymFromDateStr(end),
      user.id
    );
    return result.success
      ? { period: { start, end }, rows: result.data }
      : { error: 'Could not load rent collection report.' };
  },
};

const propertyPerformance = {
  definition: {
    type: 'function',
    function: {
      name: 'get_property_performance',
      description:
        'Compare properties over a period: units, occupied/vacant counts and income collected. ' +
        'Use for "which property performs best/worst" questions.',
      parameters: PERIOD_PARAMS,
    },
  },
  async execute(args, user) {
    const { start, end } = resolvePeriod(args);
    const result = await reportService.generatePropertyPerformanceReport(user.id, start, end);
    return result.success
      ? { period: { start, end }, properties: result.data }
      : { error: 'Could not load property performance.' };
  },
};

const paymentTrends = {
  definition: {
    type: 'function',
    function: {
      name: 'get_payment_trends',
      description:
        'Monthly income and payment counts over the last N months. Use for trend/seasonality ' +
        'questions like "how has my income changed this year".',
      parameters: {
        type: 'object',
        properties: {
          months: {
            type: 'integer',
            description: 'How many months back to include (1-24, default 12).',
          },
        },
        additionalProperties: false,
      },
    },
  },
  async execute(args, user) {
    const months = clampLimit(args && args.months, 12, 24);
    const result = await reportService.generatePaymentTrendsReport(user.id, months);
    return result.success
      ? { months, trend: result.data }
      : { error: 'Could not load payment trends.' };
  },
};

const maintenanceReport = {
  definition: {
    type: 'function',
    function: {
      name: 'get_maintenance_report',
      description:
        'Maintenance over a period: counts by status and priority, plus the most frequent ' +
        'reported problems. Use for "what maintenance issues have I had" questions.',
      parameters: PERIOD_PARAMS,
    },
  },
  async execute(args, user) {
    const { start, end } = resolvePeriod(args);
    const result = await reportService.generateMaintenanceReport(user.id, start, end);
    return result.success
      ? { period: { start, end }, ...result.data }
      : { error: 'Could not load maintenance report.' };
  },
};

const transactionReport = {
  definition: {
    type: 'function',
    function: {
      name: 'get_transactions',
      description:
        'Individual payment transactions over a period (amount, method, reference, status, date, ' +
        'tenant, property, unit), most recent first. Use for transaction listings/audits.',
      parameters: PERIOD_PARAMS,
    },
  },
  async execute(args, user) {
    const { start, end } = resolvePeriod(args);
    const result = await reportService.generateTransactionReport(user.id, start, end);
    return result.success
      ? { period: { start, end }, transactions: result.data }
      : { error: 'Could not load transactions.' };
  },
};

// ---------------------------------------------------------------------------
// Tenant tools
// ---------------------------------------------------------------------------

const myAccount = {
  definition: {
    type: 'function',
    function: {
      name: 'get_my_account',
      description:
        'Get the tenant\'s current tenancy details: property, unit, monthly rent, deposit, ' +
        'tenancy start date and status, outstanding balance, and date of their last payment.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await pool.query(
      `SELECT p.name AS property_name,
              u.unit_number,
              u.rent_amount,
              u.deposit_amount,
              t.start_date,
              t.status AS tenancy_status,
              GREATEST(
                (SELECT COALESCE(SUM(i.amount), 0) FROM invoices i
                   WHERE i.tenancy_id = t.id)
                - (SELECT COALESCE(SUM(py.amount), 0) FROM payments py
                   WHERE py.tenancy_id = t.id AND py.status = 'completed'),
                0) AS outstanding_balance,
              (SELECT MAX(py.payment_date) FROM payments py
                 WHERE py.tenancy_id = t.id AND py.status = 'completed') AS last_payment_date
         FROM tenancies t
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
        WHERE t.tenant_id = $1 AND t.status = 'active'
        ORDER BY t.start_date DESC`,
      [user.id]
    );
    if (result.rows.length === 0) return { error: 'No active tenancy found for this account.' };
    return { tenancies: result.rows };
  },
};

const paymentHistory = {
  definition: {
    type: 'function',
    function: {
      name: 'get_payment_history',
      description:
        'Get the tenant\'s recent payments (amount, method, reference, status, date, property, ' +
        'unit), most recent first. Use for payment history reports and "did my payment go ' +
        'through" questions.',
      parameters: {
        type: 'object',
        properties: {
          limit: {
            type: 'integer',
            description: 'How many recent payments to return (1-50, default 20).',
          },
        },
        additionalProperties: false,
      },
    },
  },
  async execute(args, user) {
    const limit = clampLimit(args && args.limit, 20, 50);
    const result = await pool.query(
      `SELECT py.amount,
              py.payment_method,
              py.transaction_ref,
              py.status,
              py.payment_date,
              p.name AS property_name,
              u.unit_number
         FROM payments py
         JOIN tenancies t ON py.tenancy_id = t.id
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
        WHERE t.tenant_id = $1
        ORDER BY py.payment_date DESC
        LIMIT $2`,
      [user.id, limit]
    );
    return { payments: result.rows };
  },
};

const createMaintenanceRequest = {
  definition: {
    type: 'function',
    function: {
      name: 'create_maintenance_request',
      description:
        'Log a new maintenance/repair request for the tenant\'s current unit. Only call this ' +
        'AFTER confirming the details with the user. It is sent to their landlord.',
      parameters: {
        type: 'object',
        properties: {
          title: {
            type: 'string',
            description: 'Short summary of the problem, e.g. "Leaking kitchen tap".',
          },
          description: {
            type: 'string',
            description: 'Clear details: what is wrong, where, since when, any access notes.',
          },
          category: {
            type: 'string',
            enum: MAINT_CATEGORIES,
            description: 'Best-fit category. Defaults to "other".',
          },
          priority: {
            type: 'string',
            enum: MAINT_PRIORITIES,
            description: 'Urgency. Defaults to "medium". Use "emergency" only for danger/serious risk.',
          },
        },
        required: ['title', 'description'],
        additionalProperties: false,
      },
    },
  },
  async execute(args, user) {
    const title = (args && args.title ? String(args.title) : '').trim();
    const description = (args && args.description ? String(args.description) : '').trim();
    if (!title || !description) {
      return { error: 'A short title and a clear description are both required.' };
    }

    const unitRes = await pool.query(
      `SELECT u.id AS unit_id,
              u.unit_number,
              p.name AS property_name,
              p.landlord_id,
              us.first_name,
              us.last_name
         FROM tenancies t
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         JOIN users us ON us.id = t.tenant_id
        WHERE t.tenant_id = $1 AND t.status = 'active'
        ORDER BY t.start_date DESC
        LIMIT 1`,
      [user.id]
    );
    if (unitRes.rows.length === 0) {
      return { error: 'No active tenancy found, so a maintenance request cannot be logged.' };
    }
    const unit = unitRes.rows[0];
    const category = normCategory(args && args.category);
    const priority = normPriority(args && args.priority);

    const insert = await pool.query(
      `INSERT INTO maintenance_requests (unit_id, tenant_id, title, description, category, priority)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, title, category, priority, status, created_at`,
      [unit.unit_id, user.id, title, description, category, priority]
    );
    const created = insert.rows[0];

    // Notify the landlord, mirroring the normal create flow (best-effort).
    try {
      const isEmergency = priority === 'emergency';
      const tenantName =
        `${unit.first_name || ''} ${unit.last_name || ''}`.trim() || 'A tenant';
      const where = unit.unit_number
        ? `${unit.property_name || ''} • Unit ${unit.unit_number}`.trim()
        : unit.property_name || '';
      const message = `${tenantName} reported "${title}"${where ? ' at ' + where : ''}.`;
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
         VALUES ($1, $2, $3, $4, $5, 'maintenance_request')`,
        [
          unit.landlord_id,
          isEmergency ? 'alert' : 'maintenance',
          isEmergency ? 'Emergency reported' : 'New maintenance request',
          message,
          created.id,
        ]
      );
    } catch (notifyErr) {
      console.error('Chatbot maintenance notification failed:', notifyErr.message);
    }

    return {
      created: {
        ...created,
        property_name: unit.property_name,
        unit_number: unit.unit_number,
      },
    };
  },
};

// ---------------------------------------------------------------------------
// Caretaker tools
// ---------------------------------------------------------------------------

const caretakerOverview = {
  definition: {
    type: 'function',
    function: {
      name: 'get_caretaker_overview',
      description:
        'Get a summary of the properties assigned to this caretaker: per property, the total/' +
        'occupied/vacant units and the number of open maintenance requests.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await pool.query(
      `SELECT p.id,
              p.name AS property_name,
              COUNT(u.id)::int AS total_units,
              COUNT(u.id) FILTER (WHERE u.status = 'occupied')::int AS occupied_units,
              COUNT(u.id) FILTER (WHERE u.status = 'vacant')::int AS vacant_units,
              (SELECT COUNT(*) FROM maintenance_requests mr
                 JOIN units uu ON mr.unit_id = uu.id
                WHERE uu.property_id = p.id
                  AND mr.status IN ('pending','in_progress'))::int AS open_maintenance
         FROM caretaker_assignments ca
         JOIN properties p ON ca.property_id = p.id
         LEFT JOIN units u ON u.property_id = p.id
        WHERE ca.caretaker_id = $1
        GROUP BY p.id, p.name
        ORDER BY p.name`,
      [user.id]
    );
    if (result.rows.length === 0) return { error: 'No properties are assigned to this caretaker.' };
    return { properties: result.rows };
  },
};

const openMaintenance = {
  definition: {
    type: 'function',
    function: {
      name: 'list_open_maintenance',
      description:
        'List open (pending or in-progress) maintenance requests for the caretaker\'s assigned ' +
        'properties, ordered by priority then oldest first. Includes title, description, ' +
        'category, priority, status, property, unit and tenant name.',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
    },
  },
  async execute(_args, user) {
    const result = await pool.query(
      `SELECT mr.id,
              mr.title,
              mr.description,
              mr.category,
              mr.priority,
              mr.status,
              mr.created_at,
              p.name AS property_name,
              u.unit_number,
              us.first_name || ' ' || us.last_name AS tenant_name
         FROM maintenance_requests mr
         JOIN units u ON mr.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         JOIN caretaker_assignments ca ON ca.property_id = p.id AND ca.caretaker_id = $1
         LEFT JOIN users us ON mr.tenant_id = us.id
        WHERE mr.status IN ('pending','in_progress')
        ORDER BY CASE mr.priority
                   WHEN 'emergency' THEN 0
                   WHEN 'urgent' THEN 1
                   WHEN 'high' THEN 2
                   WHEN 'medium' THEN 3
                   ELSE 4 END,
                 mr.created_at ASC
        LIMIT 50`,
      [user.id]
    );
    return { requests: result.rows };
  },
};

const updateMaintenanceStatus = {
  definition: {
    type: 'function',
    function: {
      name: 'update_maintenance_status',
      description:
        'Update the status of a maintenance request on one of the caretaker\'s assigned ' +
        'properties (e.g. mark it in_progress, completed or cancelled). Only call AFTER ' +
        'confirming with the user. Use list_open_maintenance first to get the request id. ' +
        'Marking it completed notifies the tenant.',
      parameters: {
        type: 'object',
        properties: {
          request_id: {
            type: 'integer',
            description: 'The id of the maintenance request to update.',
          },
          status: {
            type: 'string',
            enum: MAINT_STATUSES,
            description: 'The new status.',
          },
        },
        required: ['request_id', 'status'],
        additionalProperties: false,
      },
    },
  },
  async execute(args, user) {
    const requestId = parseInt(args && args.request_id, 10);
    const status = String((args && args.status) || '').toLowerCase();
    if (Number.isNaN(requestId)) return { error: 'A valid request id is required.' };
    if (!MAINT_STATUSES.includes(status)) {
      return { error: `Status must be one of: ${MAINT_STATUSES.join(', ')}.` };
    }

    // Verify the request exists AND belongs to a property this caretaker is assigned to.
    const access = await pool.query(
      `SELECT mr.id, mr.title, mr.status AS prev_status, mr.tenant_id
         FROM maintenance_requests mr
         JOIN units u ON mr.unit_id = u.id
         JOIN caretaker_assignments ca ON ca.property_id = u.property_id AND ca.caretaker_id = $2
        WHERE mr.id = $1`,
      [requestId, user.id]
    );
    if (access.rows.length === 0) {
      return { error: 'That request was not found among your assigned properties.' };
    }
    const { prev_status: prevStatus, title, tenant_id: tenantId } = access.rows[0];

    const updated = await pool.query(
      `UPDATE maintenance_requests
          SET status = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
        RETURNING id, title, status, priority, category, updated_at`,
      [status, requestId]
    );

    // Notify the tenant on completion, mirroring the maintenance controller.
    if (status === 'completed' && prevStatus !== 'completed' && tenantId) {
      try {
        await pool.query(
          `INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
           VALUES ($1, 'maintenance', $2, $3, $4, 'maintenance_request')`,
          [
            tenantId,
            'Maintenance Completed',
            `Your request "${title}" has been marked completed.`,
            requestId,
          ]
        );
      } catch (notifyErr) {
        console.error('Chatbot maintenance completion notification failed:', notifyErr.message);
      }
    }

    return { updated: updated.rows[0], previous_status: prevStatus };
  },
};

// ---------------------------------------------------------------------------
// Role -> tools mapping
// ---------------------------------------------------------------------------

const LANDLORD_TOOLS = [
  portfolioOverview,
  arrears,
  occupancy,
  incomeReport,
  rentCollectionReport,
  propertyPerformance,
  paymentTrends,
  maintenanceReport,
  transactionReport,
];

const TOOLS_BY_ROLE = {
  landlord: LANDLORD_TOOLS,
  agent: LANDLORD_TOOLS,
  tenant: [myAccount, paymentHistory, createMaintenanceRequest],
  caretaker: [caretakerOverview, openMaintenance, updateMaintenanceStatus],
};

/**
 * Returns the OpenAI tool definitions and an executor map for a given role.
 * @param {string} role
 * @returns {{ definitions: object[], executors: Record<string, Function> }}
 */
function getToolsForRole(role) {
  const tools = TOOLS_BY_ROLE[role] || [];
  const definitions = tools.map((t) => t.definition);
  const executors = {};
  for (const t of tools) executors[t.definition.function.name] = t.execute;
  return { definitions, executors };
}

module.exports = { getToolsForRole };
