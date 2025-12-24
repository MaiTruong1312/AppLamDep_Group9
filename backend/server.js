// File: server.js (Đã sửa lỗi kiểm tra người dùng trong /send-otp)

require("dotenv").config();

const express = require("express");
const nodemailer = require("nodemailer");
const bodyParser = require("body-parser");
const cors = require("cors");
const admin = require("firebase-admin"); // Khai báo Firebase Admin SDK

// ----------------------------------------------------------------------
// [BƯỚC 1] KHỞI TẠO FIREBASE ADMIN SDK
// ----------------------------------------------------------------------
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
// ----------------------------------------------------------------------

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Bộ nhớ tạm thời (Dùng cho Demo OTP)
const otpStore = {};


// ----------------------------------------------------------------------
// MIDDLEWARE KHẮC PHỤC LỖI JSON PARSING
// ----------------------------------------------------------------------
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('Bad JSON syntax or empty body received:', err);
    return res.status(400).send({ message: 'Invalid JSON format in request body or missing body.' });
  }
  next();
});
// ----------------------------------------------------------------------


// ----------------------------------------------------------------------
// 1. ENDPOINT GỬI OTP: POST /send-otp (ĐÃ SỬA: Kiểm tra email có điều kiện)
// ----------------------------------------------------------------------
app.post("/send-otp", async (req, res) => {
  // Lấy thêm tham số 'type'. Client phải gửi type='signup' hoặc type='reset'
  const { email, type } = req.body;

  if (!email) {
    return res.status(400).send({ message: "Email is required." });
  }

  // >>> BƯỚC SỬA LỖI: CHỈ KIỂM TRA SỰ TỒN TẠI NẾU LÀ 'reset' <<<
  if (type === 'reset') {
      try {
        // Nếu là reset password, BẮT BUỘC email phải tồn tại
        await admin.auth().getUserByEmail(email);
      } catch (error) {
        if (error.code === 'auth/user-not-found') {
          console.error("User not found for email (Reset context):", email);
          return res.status(404).send({ message: "The email address is not registered for password reset." });
        }
        console.error("Firebase Check Error:", error);
        return res.status(500).send({ message: "Server error during user check." });
      }
  }
  // Nếu type là 'signup' (hoặc không có), bỏ qua bước kiểm tra tồn tại.
  // >>> KẾT THÚC SỬA LỖI <<<


  const otp = Math.floor(100000 + Math.random() * 900000);
  otpStore[email] = otp.toString(); // LƯU OTP

 const transporter = nodemailer.createTransport({
     host: 'smtp.gmail.com',
     port: 465,
     secure: true,
     auth: {
       user: process.env.MAIL_USER,
       pass: process.env.MAIL_PASS,
     },
  });

  const mailOptions = {
    from: process.env.MAIL_USER,
    to: email,
    subject: type === 'signup' ? "Your Account Verification Code" : "Your Password Reset Code",
    text: `Your OTP code is: ${otp}`,
  };

  transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        // Log lỗi chi tiết
        console.error("-----------------------------------------");
        console.error("!!! NODEMAILER FAILED TO SEND EMAIL !!!");
        console.error("Email being sent to:", email);
        console.error("Nodemailer Error:", error);
        console.error("-----------------------------------------");

        if (error.code === 'EAUTH') {
          return res.status(401).send({
            message: "Authentication Failed. Check if MAIL_PASS is the correct App Password.",
            error: error.message
          });
        }

        return res.status(500).send({
            message: "Email failed. Check MAIL_PASS (App Password) and 2FA set.",
            error: error.message || "Unknown error"
        });
      }
      // Log thành công
      console.log(`OTP sent successfully to ${email} for type: ${type}. Message ID: ${info.messageId}`);
      return res.send({ message: "OTP sent", otp: otp });
    });
  });


// ----------------------------------------------------------------------
// 2. ENDPOINT XÁC THỰC OTP: POST /verify-otp
// ----------------------------------------------------------------------
app.post("/verify-otp", (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).send({ message: "Email and OTP are required." });
    }

    const storedOtp = otpStore[email];

    if (!storedOtp) {
        return res.status(404).send({ message: "OTP not found or expired." });
    }

    if (otp === storedOtp) {
        // Giữ lại OTP cho bước reset password hoặc xóa nếu là bước cuối cùng của signup
        // Tùy thuộc vào logic client gọi (client chịu trách nhiệm xóa OTP/token sau khi hoàn tất)
        delete otpStore[email];
        return res.status(200).send({ message: "OTP verified successfully." });
    } else {
        return res.status(400).send({ message: "Invalid OTP code." });
    }
});


// ----------------------------------------------------------------------
// 3. ENDPOINT ĐẶT LẠI MẬT KHẨU: POST /reset-password
// ----------------------------------------------------------------------
app.post("/reset-password", async (req, res) => {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
        return res.status(400).send({ message: "Missing email or newPassword." });
    }

    try {
        const user = await admin.auth().getUserByEmail(email);

        await admin.auth().updateUser(user.uid, {
            password: newPassword,
        });

        console.log(`Password updated successfully for user: ${email}`);
        return res.status(200).send({ message: "Password updated successfully." });

    } catch (error) {
        console.error("Firebase Reset Password Error:", error);
        return res.status(500).send({ message: "Failed to update password in Firebase.", error: error.message || "Unknown error" });
    }
});


app.listen(3000, '0.0.0.0', () => console.log("Server running on port 3000"));