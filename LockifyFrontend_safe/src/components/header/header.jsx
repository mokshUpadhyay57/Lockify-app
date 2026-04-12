import React, { useState } from "react";
import "./header.css";
import { Link } from "react-router-dom";
import logo from "../../assets/lockify_v1.jpg";

export default function Header() {
  function toggle() {
    const nav = document.querySelector(".menu");
    nav.style.display = nav.style.display === "none" ? "flex" : "none";
  }

  return (
    <>
      <header className="admin-header-bar">
        <div className="admin-header-logo">
          <Link to="/">
            <img src={logo} alt="Lockify Logo" />
          </Link>
        </div>
        
        <nav className="admin-header-nav menu">
          <Link to="/" className="admin-header-link">
            Home
          </Link>
          <Link to="/about" className="admin-header-link">
            About
          </Link>
          <Link to="/services" className="admin-header-link">
            Services
          </Link>
          <Link to="/contact" className="admin-header-link">
            Contact
          </Link>
          <Link to="/login" className="admin-header-link">
            Login
          </Link>
        </nav>
        <div className="hamburger" onClick={toggle}>
          <img src="src/assets/hamburger.svg" alt="Menu" />
        </div>
      </header>
    </>
  );
}
