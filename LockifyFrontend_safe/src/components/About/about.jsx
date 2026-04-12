import "./about.css";
// import aboutImage from "../assets/about-lockify.png"; // Replace with your app's image

export default function About() {
  return (
    <section className="about">
      <div className="about-container">
        {/* Left Section - Image */}
        <div className="about-image">image</div>

        {/* Right Section - Content */}
        <div className="about-content">
          <h1>About Lockify</h1>
          <p>
            Lockify is a secure, fast, and innovative platform designed to
            simplify how you **create, connect, and communicate**. Our mission
            is to provide a seamless experience that blends powerful features
            with an easy-to-use interface.
          </p>

          <p>
            Whether it’s **content creation**, **group chats**, or sharing
            updates, Lockify ensures your data stays **private** while keeping
            you **connected**. We’re committed to delivering a smooth and
            intuitive experience that adapts to your needs.
          </p>

          <div className="about-stats">
            <div className="stat-box">
              <h2>50K+</h2>
              <span>Active Users</span>
            </div>
            <div className="stat-box">
              <h2>1M+</h2>
              <span>Messages Sent</span>
            </div>
            <div className="stat-box">
              <h2>99.9%</h2>
              <span>Uptime Guarantee</span>
            </div>
          </div>

          <button className="about-btn">Learn More</button>
        </div>
      </div>
    </section>
  );
}
