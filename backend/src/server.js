const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

const authMiddleware = require('./middleware/auth.middleware');

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/properties', authMiddleware, require('./routes/property.routes'));
app.use('/api/units', authMiddleware, require('./routes/unit.routes'));
app.use('/api/tenancies', authMiddleware, require('./routes/tenancy.routes'));
app.use('/api/payments', authMiddleware, require('./routes/payment.routes'));
app.use('/api/maintenance', authMiddleware, require('./routes/maintenance.routes'));

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
