import React, { useState } from "react";
import "./Contact.css";

export default function Contact() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    message: "",
  });

  const [submitted, setSubmitted] = useState(false);

  // Handle input changes
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  // Handle form submission
  const handleSubmit = (e) => {
    e.preventDefault();
    console.log("Form submitted:", formData);
    setSubmitted(true);

    // Reset form
    setFormData({ name: "", email: "", message: "" });

    // You can integrate an API like EmailJS here to send messages
  };

  return (
    <section className="contact">
      <div className="contact-container">
        {/* Left Side - Contact Info */}
        <div className="contact-info">
          <h1>Contact Us</h1>
          <p>
            Have questions, feedback, or need support? Reach out to us and we'll
            get back to you as soon as possible.
          </p>

          <div className="info-box">
            <h3>Email</h3>
            <p>support@lockify.com</p>
          </div>

          <div className="info-box">
            <h3>Phone</h3>
            <p>+91 98765 43210</p>
          </div>

          <div className="info-box">
            <h3>Address</h3>
            <p>Lockify HQ, Bengaluru, India</p>
          </div>
        </div>

        {/* Right Side - Contact Form */}
        <div className="contact-form">
          <h2>Send us a message</h2>
          {submitted && (
            <p className="success-msg">✅ Message sent successfully!</p>
          )}

          <form onSubmit={handleSubmit}>
            {/* Name */}
            <div className="form-group">
              <label htmlFor="name">Full Name</label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleChange}
                placeholder="Enter your full name"
                required
              />
            </div>

            {/* Email */}
            <div className="form-group">
              <label htmlFor="email">Email Address</label>
              <input
                type="email"
                id="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                placeholder="Enter your email"
                required
              />
            </div>

            {/* Message */}
            <div className="form-group">
              <label htmlFor="message">Your Message</label>
              <textarea
                id="message"
                name="message"
                value={formData.message}
                onChange={handleChange}
                placeholder="Write your message..."
                rows="5"
                required
              ></textarea>
            </div>

            {/* Submit Button */}
            <button type="submit" className="contact-btn">
              Send Message
            </button>
          </form>
        </div>
      </div>
    </section>
  );
}
