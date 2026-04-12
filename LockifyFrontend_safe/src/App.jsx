import { Routes, Route } from "react-router-dom";

import Home from "./components/Home/home";
import About from "./components/About/about";
import Contact from "./components/Contact/contact";
import Services from "./components/Services/services";
import Login from "./components/Login/login";
import Header from "./components/Header/header";
import Footer from "./components/Footer/footer";

const App = () => {
  return (
    <div className="app">
      <Header />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/services" element={<Services />} />
        <Route path="/login" element={<Login />} />
      </Routes>
      <Footer />
    </div>
  );
};

export default App;
