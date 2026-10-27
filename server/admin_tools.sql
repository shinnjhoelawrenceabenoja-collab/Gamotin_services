-- Handy queries. Run with:  psql -U postgres -d gamotin -f admin_tools.sql   (or paste into psql)

-- Make an existing customer an admin (change the phone number)
-- UPDATE users SET role = 'admin' WHERE phone = '09123456789';

-- See all users
SELECT id, name, phone, email, role, created_at FROM users ORDER BY id;

-- See pending orders with the customer's contact info
SELECT o.id, u.name, u.phone, o.copies, o.color, o.paper_size, o.paper_type, o.duplex, o.created_at
FROM orders o JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending' ORDER BY o.id;

-- Delete login sessions older than 60 days
-- DELETE FROM sessions WHERE created_at < now() - interval '60 days';
