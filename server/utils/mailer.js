const nodemailer = require('nodemailer');
require('dotenv').config();  

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true, // TLS
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

function sendResolutionEmail(to, subject, text) {
  const mailOptions = {
    from: process.env.EMAIL_USER, // admin email from .env
    to, // resolved user's email
    subject,
    text
  };
  return transporter.sendMail(mailOptions);
}

module.exports = { sendResolutionEmail }; 