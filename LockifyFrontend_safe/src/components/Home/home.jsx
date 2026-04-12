import "./home.css";
// import appImage from "../assets/app-mockup.png"; // replace with your app screenshot

const services = [
  {
    title: "Locked Messages",
    description:
      "Share premium content securely. Users unlock it with payments.",
    image: "/images/locked-message.png",
  },
  {
    title: "Monetize Content",
    description:
      "Turn your posts into earnings with built-in monetization tools.",
    image: "/images/monetize.png",
  },
  // {
  //   title: "Subscription Plans",
  //   description:
  //     "Offer exclusive access through monthly or yearly subscriptions.",
  //   image: "/images/subscription.png",
  // },
  {
    title: "Analytics",
    description:
      "Track your audience engagement and revenue performance.",
    image: "/images/analytics.png",
  },
  {
    title: "Secure Payments",
    description:
      "Payments are encrypted and safe, giving you peace of mind.",
    image: "/images/payments.png",
  },
  {
    title: "Community Growth",
    description:
      "Engage your followers and build a loyal supporter base.",
    image: "/images/community.png",
  },
];

const heroText = "Private chats. Exclusive content. Community growth. Monetize securely — all with Lockify.";

export default function Home() {
  return (
    <div className="home">
      {/* Hero Section */}
      <section className="hero">
        <div className="hero-content">
          <div className="hero-text">
            <h1>
              Welcome to <span className="highlight">Lockify</span>
            </h1>
            <p>
              {heroText}
            </p>

            <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
              {/* // add download link from playstore later */}
              <a href="/download/app.apk" download aria-label="Download Lockify App">
                <button className="btn">Download App</button>
              </a>
              <a href="#features-heading" aria-label="See Features">
                <button className="btn" style={{ background: '#fff', color: '#7c3aed', border: '2px solid #7c3aed' }}>See Features</button>
              </a>
            </div>
          </div>
          <div className="hero-image">
            <img src="/images/app-mockup.png" alt="Lockify App Screenshot" style={{ maxWidth: 320, borderRadius: 16, boxShadow: '0 4px 24px rgba(124,58,237,0.13)' }} />
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features" aria-labelledby="features-heading">
        <h2 id="features-heading">Features for the app</h2>
        <ul>
          <li>Secure group and channel chats for users</li>
          <li>Locked messages and premium content sharing</li>
          {/* <li>Comprehensive admin dashboard for managing users, content, and payments</li> */}
          <li>Polls, announcements, and community engagement tools</li>
          <li>Wallet, earnings management, and analytics</li>
          <li>Easy user registration, verification, and access control</li>
        </ul>
      </section>

      {/* Services Section */}
      <section className="services" aria-labelledby="services-heading">
        <h2 id="services-heading">Solutions For Creators</h2>
        <div className="services-grid">
          {services.map((service, index) => (
            <div key={index} className="service-card">
              <img
                src={service.image}
                alt={service.title}
                className="service-img"
              />
              <h3 className="service-title">{service.title}</h3>
              <p className="service-desc">{service.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="testimonials" aria-labelledby="testimonials-heading">
        <h2 id="testimonials-heading">What Our Users Say</h2>
        <div className="testimonials-row-scroll">
          <div className="testimonial-card">
            <p>“The locked messages and payment features are a game changer for creators like me.”</p>
            <span>- Alex R., Content Creator, USA</span>
          </div>
          <div className="testimonial-card">
            <p>“I love the analytics and the ability to monetize my content. Lockify is a must-have!”</p>
            <span>- Maria G., Influencer, UK</span>
          </div>
          <div className="testimonial-card">
            <p>“The subscription plans helped me grow a loyal community. The platform is super easy to use.”</p>
            <span>- Rajesh K., Educator, India</span>
          </div>
          <div className="testimonial-card">
            <p>“Payments are fast and secure. I feel confident using Lockify for my business.”</p>
            <span>- Sophie L., Entrepreneur, Canada</span>
          </div>
          <div className="testimonial-card">
            <p>“The support team is responsive and helpful. I recommend Lockify to all my friends.”</p>
            <span>- Arjun M., Community Leader, India</span>
          </div>
          <div className="testimonial-card">
            <p>“Finally, a platform that makes content monetization simple and safe.”</p>
            <span>- Isabella R., Creator, Australia</span>
          </div>
          <div className="testimonial-card">
            <p>“Lockify’s features helped me grow my online classes and engage students better.”</p>
            <span>- Ananya S., Teacher, India</span>
          </div>
        </div>
      </section>


      {/* Newsletter Signup Section */}
      <section className="newsletter" aria-labelledby="newsletter-heading">
        <h2 id="newsletter-heading">Stay Updated</h2>
        <form className="newsletter-form">
          <input type="email" placeholder="Your Email Address" required />
          <button type="submit" className="btn">Subscribe</button>
        </form>
      </section>

      {/* FAQ Section */}
      <section className="faq" aria-labelledby="faq-heading">
        <h2 id="faq-heading">Frequently Asked Questions</h2>
        <div className="faq-list">
          <div className="faq-item">
            <strong>Is Lockify free to use?</strong>
            <p>Lockify offers both free and premium plans. You can get started for free!</p>
          </div>
          <div className="faq-item">
            <strong>How do I monetize my content?</strong>
            <p>You can set up locked messages or subscription plans from your dashboard. Admins can manage payouts and monitor earnings.</p>
          </div>
          <div className="faq-item">
            <strong>Is my data secure?</strong>
            <p>Yes, all messages, user data, and payments are encrypted and protected with industry-standard security.</p>
          </div>
          <div className="faq-item">
            <strong>What platforms are supported?</strong>
            <p>Lockify is available as a mobile app for users (iOS and Android) and a web-based admin panel for administrators.</p>
          </div>
          <div className="faq-item">
            <strong>How do I get support?</strong>
            <p>You can contact our support team anytime via the contact form below or email us at support@lockify.com.</p>
          </div>
          <div className="faq-item">
            <strong>Can I customize my community or channel?</strong>
            <p>Yes! Lockify allows you to brand your community, set custom rules, and manage permissions for members.</p>
          </div>
        </div>
      </section>
    </div>
  );
}
