# KodiPay - Rental Management System

A scalable rental management platform for landlords, tenants, caretakers, and agents with secure M-Pesa payment integration.

## 🚀 Features

### Phase 1: Core System (Launchable)
- ✅ **Authentication with roles** - JWT-based auth for landlords, tenants, caretakers, and agents
- ✅ **Property & tenant management** - Complete CRUD for properties, units, and tenancies
- ✅ **Rent ledger system** - Track rent payments and balances
- ✅ **Manual payment recording** - Record payments via multiple methods
- ✅ **Maintenance system** - Tenants can report issues with image support

### Phase 2: Payments
- ✅ **M-Pesa STK Push** - Initiate payments directly from the app
- ✅ **Webhook callbacks** - Automatic payment confirmation via M-Pesa
- ✅ **Auto reconciliation** - Payments automatically update ledger and payment status

## 🛠 Tech Stack

- **Backend**: Node.js with Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Tokens)
- **Payments**: M-Pesa Daraja API
- **Security**: bcrypt, helmet, CORS

## 📋 Prerequisites

- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- M-Pesa Daraja API credentials (for payments)

## ⚙️ Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/Johnnierad24/KodiPay.git
cd KodiPay/backend
```

### 2. Install dependencies
```bash
npm install
```

### 3. Database setup
- Create a PostgreSQL database named `kodipay`
- Update the `.env` file with your database credentials
- Run the schema SQL file:
```bash
psql -U postgres -d kodipay -f db/schema.sql
```

### 4. Configure environment variables
Edit the `.env` file with your credentials:
```env
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kodipay
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your_super_secret_jwt_key
NODE_ENV=development

# M-Pesa credentials (get from https://developer.safaricom.co.ke)
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_SHORTCODE=174379
MPESA_PASSKEY=your_passkey
MPESA_CALLBACK_URL=https://yourdomain.com/api/payments/mpesa/callback
MPESA_ENV=sandbox
```

### 5. Start the server
```bash
npm start
```

Server will run on `http://localhost:5000`

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user (landlord/tenant/caretaker/agent)
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info

### Properties
- `GET /api/properties` - List all properties
- `POST /api/properties` - Create new property
- `GET /api/properties/:id` - Get property details
- `PUT /api/properties/:id` - Update property
- `DELETE /api/properties/:id` - Delete property

### Units
- `GET /api/units/property/:propertyId` - List units in property
- `POST /api/units` - Create new unit
- `GET /api/units/:id` - Get unit details
- `PUT /api/units/:id` - Update unit
- `DELETE /api/units/:id` - Delete unit

### Tenancies
- `GET /api/tenancies` - List all tenancies
- `POST /api/tenancies` - Create new tenancy
- `GET /api/tenancies/:id` - Get tenancy details
- `PUT /api/tenancies/:id` - Update tenancy
- `DELETE /api/tenancies/:id` - End tenancy

### Payments
- `POST /api/payments` - Record payment (manual or M-Pesa STK Push)
- `GET /api/payments/tenancy/:tenancyId` - Get payments for tenancy
- `GET /api/payments/:id` - Get payment details
- `PUT /api/payments/:id` - Update payment status
- `POST /api/payments/mpesa/callback` - M-Pesa webhook callback

### Maintenance
- `POST /api/maintenance` - Create maintenance request
- `GET /api/maintenance/unit/:unitId` - Get requests for unit
- `GET /api/maintenance/:id` - Get request details
- `PUT /api/maintenance/:id` - Update request
- `PUT /api/maintenance/:id/status` - Update request status

## 💳 Getting M-Pesa Credentials

1. Register at [Safaricom Developer Portal](https://developer.safaricom.co.ke)
2. Create a new app to get Consumer Key and Consumer Secret
3. For testing: Use sandbox shortcode `174379` and test passkey
4. For production: Apply for Lipa Na M-Pesa shortcode

## 🗄 Database Schema

The system uses PostgreSQL with the following main tables:
- `users` - User accounts with roles
- `properties` - Property listings
- `units` - Individual rental units/apartments
- `tenancies` - Links tenants to units
- `payments` - Payment records
- `ledger_entries` - Rent ledger transactions
- `maintenance_requests` - Maintenance tickets
- `notifications` - User notifications

## 🔐 Security Features

- Password hashing with bcrypt
- JWT token authentication
- Protected API endpoints with auth middleware
- Input validation with express-validator
- Security headers with helmet
- CORS protection

## 🚧 Upcoming Phases

- **Phase 3**: Automation (SMS reminders, auto invoices, notifications)
- **Phase 4**: Intelligence Layer (Reports, analytics, AI chatbot)
- **Phase 5**: Expansion (Marketplace, KRA integration, premium features)

## 📝 License

MIT License

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 📧 Contact

For questions or support, please open an issue on GitHub.
