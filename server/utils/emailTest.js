const nodemailer = require('nodemailer');
require('dotenv').config();  // Load from parent folder

async function sendTestEmail() {
  try {
    let transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true,
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
      debug: true,
    });

    let info = await transporter.sendMail({
      from: `"Campus System" <${process.env.EMAIL_USER}>`,
      to: process.env.EMAIL_TO,
      subject: 'Test Email from College Campus Complaint System ✅',
      text: 'This is a test email sent from your system successfully.',
    });

    console.log('✅ Email sent successfully! Message ID:', info.messageId);
  } catch (err) {
    console.error('❌ Error sending email:', err);
  }
}

sendTestEmail();
