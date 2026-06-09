#!/bin/bash
dnf update -y
dnf install -y nodejs npm git

mkdir -p /home/ec2-user/student-app
cd /home/ec2-user/student-app

cat > package.json <<'EOF'
{
  "name": "student-management-app",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.9.0",
    "ejs": "^3.1.9"
  }
}
EOF

cat > server.js <<'EOF'
const express = require("express");
const mysql = require("mysql2/promise");

const app = express();
app.use(express.urlencoded({ extended: true }));
app.set("view engine", "ejs");

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

async function initDb() {
  const connection = await mysql.createConnection(dbConfig);

  await connection.execute(`
    CREATE TABLE IF NOT EXISTS students (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      age INT,
      class_name VARCHAR(50)
    )
  `);

  await connection.end();
}

app.get("/", async (req, res) => {
  const connection = await mysql.createConnection(dbConfig);
  const [students] = await connection.execute("SELECT * FROM students");
  await connection.end();

  res.render("index", { students });
});

app.post("/students", async (req, res) => {
  const { name, age, class_name } = req.body;

  const connection = await mysql.createConnection(dbConfig);
  await connection.execute(
    "INSERT INTO students(name, age, class_name) VALUES (?, ?, ?)",
    [name, age, class_name]
  );
  await connection.end();

  res.redirect("/");
});

initDb().then(() => {
  app.listen(3000, "0.0.0.0", () => {
    console.log("Student app running on port 3000");
  });
});
EOF

mkdir -p views

cat > views/index.ejs <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Student Management</title>
  <style>
    body {
      font-family: Arial;
      margin: 40px;
    }

    input {
      padding: 8px;
      margin: 5px;
    }

    button {
      padding: 8px 12px;
    }

    table {
      border-collapse: collapse;
      width: 70%;
      margin-top: 20px;
    }

    th, td {
      border: 1px solid #ccc;
      padding: 10px;
    }
  </style>
</head>
<body>
  <h1>Student Management System</h1>

  <form action="/students" method="POST">
    <input type="text" name="name" placeholder="Student name" required>
    <input type="number" name="age" placeholder="Age">
    <input type="text" name="class_name" placeholder="Class">
    <button type="submit">Add Student</button>
  </form>

  <table>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Age</th>
      <th>Class</th>
    </tr>

    <% students.forEach(student => { %>
      <tr>
        <td><%= student.id %></td>
        <td><%= student.name %></td>
        <td><%= student.age || "" %></td>
        <td><%= student.class_name || "" %></td>
      </tr>
    <% }) %>
  </table>
</body>
</html>
EOF

npm install

cat > .env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
EOF

cat > start.sh <<'EOF'
#!/bin/bash
cd /home/ec2-user/student-app
export $(cat .env | xargs)
npm start
EOF

chmod +x start.sh

cat > /etc/systemd/system/student-app.service <<'EOF'
[Unit]
Description=Student Management Node App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/student-app
ExecStart=/home/ec2-user/student-app/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable student-app
systemctl start student-app