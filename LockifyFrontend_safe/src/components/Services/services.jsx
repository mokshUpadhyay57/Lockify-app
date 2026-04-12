import "./Services.css";

export default function Services() {
  return (
    <section className="services">
      <div className="services-header">
        <h1>Our Features</h1>
        <p>
          Discover the powerful tools Lockify offers to make your experience
          seamless, secure, and enjoyable.
        </p>
      </div>

      <div className="services-container">
        {/* Content Creation Feature */}
        <div className="service-card">
          <div className="service-image service-placeholder">📝</div>
          <h2>Content Creation</h2>
          <p>
            Create, edit, and manage content effortlessly. Lockify provides
            intuitive tools to help you publish creative posts and engage with
            your audience effectively.
          </p>
        </div>

        {/* Group Chat Feature */}
        <div className="service-card">
          <div className="service-image service-placeholder">💬</div>
          <h2>Group Chat</h2>
          <p>
            Connect with your friends, colleagues, or followers through
            real-time group chats. Share media, collaborate, and stay in touch
            with ease and security.
          </p>
        </div>
      </div>
    </section>
  );
}
