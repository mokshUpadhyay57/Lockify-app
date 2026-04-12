import LockedMessages from "./lockedMessages";

const CODE_REGEX = /^[A-Za-z0-9]{6}$/;
const PATH_REGEX = /^\/?([A-Za-z0-9]{6})\/?$/;

function getCode() {
  const params = new URLSearchParams(window.location.search);
  const q = params.get("code");
  if (q && CODE_REGEX.test(q)) return q;

  const m = window.location.pathname.match(PATH_REGEX);
  return m ? m[1] : null;
}

function Payment() {
  const code = getCode();
  if (!code) {
    return (
      <div style={{ textAlign: "center", padding: "50px" }}>
        <h2>Invalid Access</h2>
        <p>No unlock code found in the URL. Please use the link provided by the creator or enter the code on the home page.</p>
        <a href="/" style={{ color: "#7c3aed", fontWeight: "bold" }}>Go to Home Page</a>
      </div>
    );
  }
  return (
    <>
      <LockedMessages code={code} />
    </>
  );
}
export default Payment;