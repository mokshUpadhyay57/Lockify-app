import "./Footer.css";
import { FaLocationDot } from "react-icons/fa6";
import { MdEmail } from "react-icons/md";
import { FaPhoneAlt } from "react-icons/fa";
import { FaArrowUp } from "react-icons/fa6";

export default function Footer() {
  return (
    <footer className="footer">
      {/* Upper Section */}
      <div className="footer-container">
        {/* Description */}
        <div className="footer-about">
          <p>
            Welcome to <strong>Lockify</strong>, your trusted platform for
            secure data storage and seamless file management. Experience
            cutting-edge encryption and hassle-free sharing with Lockify.
          </p>
        </div>

        {/* Company Links */}
        <div className="footer-column">
          <h3>Company</h3>
          <a href="#">About Us</a>
          <a href="#">Services</a>
          <a href="#">Contact Us</a>
        </div>

        {/* Legal Links */}
        <div className="footer-column">
          <h3>Legal</h3>
          <a href="#">Privacy Policy</a>
          <a href="#">Terms & Conditions</a>
          <a href="#">Refund & Cancellation</a>
        </div>

        {/* Contact Info */}
        <div className="footer-column">
          <h3>Contact Us</h3>
          <p>
            <FaLocationDot className="footer-icon" /> 221B Baker Street, London,
            UK
          </p>
          <p>
            <MdEmail className="footer-icon" /> support@lockify.com
          </p>
          <p>
            <FaPhoneAlt className="footer-icon" /> +44 1234 567890
          </p>
        </div>
      </div>

      {/* Bottom Bar */}
      {/* <div className="footer-bottom">
        © 2025 Lockify Technologies. All Rights Reserved.
      </div>
      <a className="scroll-top-btn" href="#top" aria-label="Scroll to top">
        <FaArrowUp />
      </a> */}
    </footer>
  );
}
