const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Pool configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Init DB Tables
async function initDb() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        email TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        password TEXT,
        photo_url TEXT,
        auth_provider TEXT NOT NULL
      );
    `);
    await client.query(`
      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        is_expense INTEGER NOT NULL,
        wallet TEXT NOT NULL,
        date TEXT NOT NULL,
        user_email TEXT NOT NULL,
        FOREIGN KEY (user_email) REFERENCES users (email) ON DELETE CASCADE
      );
    `);
    await client.query(`
      CREATE TABLE IF NOT EXISTS budgets (
        category TEXT,
        amount DOUBLE PRECISION NOT NULL,
        user_email TEXT,
        PRIMARY KEY (category, user_email)
      );
    `);
    console.log('Database tables initialized successfully');
  } catch (err) {
    console.error('Error initializing database tables:', err);
  } finally {
    client.release();
  }
}

// Routes

// 1. User routes
app.post('/api/users', async (req, res) => {
  const { email, display_name, password, photo_url, auth_provider } = req.body;
  try {
    const query = `
      INSERT INTO users (email, display_name, password, photo_url, auth_provider)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (email) DO UPDATE 
      SET display_name = EXCLUDED.display_name, 
          photo_url = EXCLUDED.photo_url, 
          auth_provider = EXCLUDED.auth_provider
      RETURNING *;
    `;
    const result = await pool.query(query, [email, display_name, password, photo_url, auth_provider]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/users/:email', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE LOWER(email) = LOWER($1)', [req.params.email]);
    if (result.rows.length > 0) {
      res.json(result.rows[0]);
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Transaction routes
app.post('/api/transactions', async (req, res) => {
  const { title, category, amount, is_expense, wallet, date, user_email } = req.body;
  try {
    const query = `
      INSERT INTO transactions (title, category, amount, is_expense, wallet, date, user_email)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const result = await pool.query(query, [title, category, amount, is_expense, wallet, date, user_email]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/transactions/:id', async (req, res) => {
  const { title, category, amount, is_expense, wallet, date, user_email } = req.body;
  try {
    const query = `
      UPDATE transactions 
      SET title = $1, category = $2, amount = $3, is_expense = $4, wallet = $5, date = $6, user_email = $7
      WHERE id = $8
      RETURNING *;
    `;
    const result = await pool.query(query, [title, category, amount, is_expense, wallet, date, user_email, req.params.id]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/transactions/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM transactions WHERE id = $1', [req.params.id]);
    res.json({ message: 'Transaction deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/transactions', async (req, res) => {
  const { email, startDate, endDate } = req.query;
  try {
    let query = 'SELECT * FROM transactions WHERE LOWER(user_email) = LOWER($1)';
    const params = [email];
    if (startDate) {
      params.push(startDate);
      query += ` AND date >= $${params.length}`;
    }
    if (endDate) {
      params.push(endDate);
      query += ` AND date <= $${params.length}`;
    }
    query += ' ORDER BY date DESC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/summary', async (req, res) => {
  const { email, startDate, endDate } = req.query;
  try {
    let incomeQuery = 'SELECT SUM(amount) as total FROM transactions WHERE LOWER(user_email) = LOWER($1) AND is_expense = 0';
    let expenseQuery = 'SELECT SUM(amount) as total FROM transactions WHERE LOWER(user_email) = LOWER($1) AND is_expense = 1';
    const params = [email];
    if (startDate) {
      params.push(startDate);
      incomeQuery += ` AND date >= $${params.length}`;
      expenseQuery += ` AND date >= $${params.length}`;
    }
    if (endDate) {
      params.push(endDate);
      incomeQuery += ` AND date <= $${params.length}`;
      expenseQuery += ` AND date <= $${params.length}`;
    }
    const incomeResult = await pool.query(incomeQuery, params);
    const expenseResult = await pool.query(expenseQuery, params);
    const totalIncome = parseFloat(incomeResult.rows[0].total) || 0;
    const totalExpense = parseFloat(expenseResult.rows[0].total) || 0;
    res.json({
      balance: totalIncome - totalExpense,
      income: totalIncome,
      expense: totalExpense
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Budget routes
app.post('/api/budgets', async (req, res) => {
  const { category, amount, user_email } = req.body;
  try {
    const query = `
      INSERT INTO budgets (category, amount, user_email)
      VALUES ($1, $2, $3)
      ON CONFLICT (category, user_email) DO UPDATE 
      SET amount = EXCLUDED.amount
      RETURNING *;
    `;
    const result = await pool.query(query, [category, amount, user_email]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/budgets', async (req, res) => {
  const { email } = req.query;
  try {
    const result = await pool.query('SELECT * FROM budgets WHERE LOWER(user_email) = LOWER($1)', [email]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/budgets', async (req, res) => {
  const { category, email } = req.query;
  try {
    await pool.query('DELETE FROM budgets WHERE category = $1 AND LOWER(user_email) = LOWER($2)', [category, email]);
    res.json({ message: 'Budget deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/budgets/expense-by-category', async (req, res) => {
  const { email } = req.query;
  try {
    const query = `
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE LOWER(user_email) = LOWER($1) AND is_expense = 1
      GROUP BY category;
    `;
    const result = await pool.query(query, [email]);
    // Convert to { category: total } object format
    const budgetMap = {};
    result.rows.forEach(row => {
      budgetMap[row.category] = parseFloat(row.total) || 0;
    });
    res.json(budgetMap);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  initDb();
});
