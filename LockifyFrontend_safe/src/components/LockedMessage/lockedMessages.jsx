import { db, storage } from "./firebase";
import { useState, useEffect } from "react";
import { collection, query, where, getDocs, doc, onSnapshot } from "firebase/firestore";
import UpiPaymentModal from "./paymentOptions/src/upiPaymentModal";

import "./lockedMessages.css";
import { useCashfreePayment } from "./hooks/useCashfreePayment"
import { useImageCache } from "./hooks/useImageCache";
import { CardComponent } from "./paymentOptions/src/cardComponent";
import { WalletComponent } from "./paymentOptions/src/walletComponent";

const BUYER_PHONE_STORAGE_KEY = "lockify_buyer_phone";

const getSafeMediaUrl = (value) => {
  if (typeof value !== "string") return "";
  return value.trim();
};

const LockedMessages = ({ code }) => {
  const payment = useCashfreePayment();
  const { hasAccess, setHasAccess } = payment;
  const { imageUrls, fetchImage } = useImageCache(storage);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [isResolvingEntitlement, setIsResolvingEntitlement] = useState(false);
  const [buyerPhone, setBuyerPhone] = useState(() => {
    const savedPhone = sessionStorage.getItem(BUYER_PHONE_STORAGE_KEY) || "";
    return String(savedPhone).replace(/\D/g, "").slice(0, 10);
  });
  const [phoneError, setPhoneError] = useState("");

const options = [
    { name: "UPI", icon: "💰" },
    { name: "Card", icon: "💳" },
    { name: "Wallet", icon: "👜" },
  ];

  const selectedMessage = messages[0] || null;
  const unlockPrice = Number(selectedMessage?.unlockPrice || 0);
  const selectedMessageId = selectedMessage?.id || "";
  const normalizedBuyerPhone = String(buyerPhone).replace(/\D/g, "").slice(-10);
  const isValidBuyerPhone = /^\d{10}$/.test(normalizedBuyerPhone);

  useEffect(() => {
    if (normalizedBuyerPhone) {
      sessionStorage.setItem(BUYER_PHONE_STORAGE_KEY, normalizedBuyerPhone);
      return;
    }
    sessionStorage.removeItem(BUYER_PHONE_STORAGE_KEY);
  }, [normalizedBuyerPhone]);

  // // ---------- Payment handler ----------
  // const handlePayment = async () => {
  //   try {
  //     const { payment_session_id, order_id } = await createOrderAndReturnPaymentSession();
  //     console.log(`In handlePayment() Obtained session ID: ${payment_session_id}, order ID: ${order_id}`);
  //     const checkoutOptions = {
  //       paymentSessionId: payment_session_id,
  //       mode: "Sandbox",
  //       redirectTarget: "_modal",
  //     };

  //     cashfree.checkout(checkoutOptions)
  //     .then((res) => {
  //       console.info("Payment result:", res);
  //       // verify paymenyt after checkout
  //       const verifyResponse = verifyPayment(order_id);
  //       if (verifyResponse.data.order_status === "PAID") {
  //         console.log("Order ID for verification:", order_id);
  //         console.log(`order status after verification: ${verifyResponse.data.order_status}`);
  //         setHasAccess(true);
  //       }
  //     })
  //     .catch((err) => {
  //       console.error("Payment error:", err);
  //     });
  //   } catch (err) {
  //     console.error("Payment failed:", err);
  //   }
  // };

  useEffect(() => {
    let alive = true;
    const load = async () => {
      try {
        const refCol = collection(db, "lockedMessages");
        const q = query(refCol, where("uniqueCode", "==", code));
        const snap = await getDocs(q);

        // 1️⃣ Extract message data (price preserved)
        const docs = snap.docs.map((doc) => {
          const data = doc.data();
          return { ...data, id: doc.id };
        });

        // 2️⃣ Render immediately
        if (alive) {
          setMessages(docs);
          if (docs.length === 0) {
            setError(
              "Invalid or expired unlock code. Please check the code and try again.",
            );
          }
        }

        // 3️⃣ Load images in background (non-blocking)
        docs.forEach((msg) => {
          fetchImage(msg.id, msg.imageUrl, alive);
        });
      } catch (e) {
        if (alive) setError("Failed to fetch locked messages.", e);
      } finally {
        if (alive) setLoading(false);
      }
    };

    load();
    return () => {
      alive = false;
    };
  }, [code, fetchImage]);

  useEffect(() => {
    if (!selectedMessageId || !isValidBuyerPhone) {
      setIsResolvingEntitlement(false);
      setHasAccess(false);
      return;
    }

    // Reset entitlement when watcher context changes (new phone/message).
    setHasAccess(false);
    setIsResolvingEntitlement(true);

    const orderItemId = `${normalizedBuyerPhone}_${selectedMessageId}`;
    const orderItemRef = doc(db, "order-items", orderItemId);

    const unsubscribe = onSnapshot(
      orderItemRef,
      (orderItemSnapshot) => {
        // Keep optimistic unlock if verify API already marked access true.
        setHasAccess((prev) => prev || orderItemSnapshot.exists());
        setIsResolvingEntitlement(false);
      },
      (snapshotError) => {
        console.error("Failed to watch order-item entitlement:", snapshotError);
        setHasAccess(false);
        setIsResolvingEntitlement(false);
      },
    );

    return () => unsubscribe();
  }, [selectedMessageId, normalizedBuyerPhone, isValidBuyerPhone, setHasAccess]);

  useEffect(() => {
    if (hasAccess) {
      setIsResolvingEntitlement(false);
    }
  }, [hasAccess]);

  useEffect(() => {
    if (!hasAccess || messages.length === 0) return;

    let alive = true;
    messages.forEach((msg) => {
      fetchImage(msg.id, msg.imageUrl, alive);
    });

    return () => {
      alive = false;
    };
  }, [hasAccess, messages, fetchImage]);

  if (error) return <p style={{ color: "red" }}>{error}</p>;

  const isUnlockPending =
    !hasAccess && (payment.isVerifyingReturn || isResolvingEntitlement);

  return (
    <>
      <div className="locked-container">
        {loading && <div className="locked-skeleton" />}

        {!loading &&
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`locked-image-box ${hasAccess ? "unlocked" : ""}`}
            >
              {(() => {
                const imageSrc = getSafeMediaUrl(imageUrls[msg.id]) || getSafeMediaUrl(msg.imageUrl);
                const videoSrc = getSafeMediaUrl(msg.videoUrl);
                const documentSrc = getSafeMediaUrl(msg.documentUrl);

                if (imageSrc) {
                  return (
                    <img
                      src={imageSrc}
                      alt="Locked"
                      className="locked-image"
                    />
                  );
                }

                if (videoSrc) {
                  if (!hasAccess) {
                    return (
                      <div className="locked-media-fallback">
                        <span className="locked-media-icon">🎥</span>
                        <p>{isUnlockPending ? "Verifying payment..." : "Video available after unlock"}</p>
                      </div>
                    );
                  }
                  return (
                    <video
                      src={videoSrc}
                      className="locked-image"
                      controls
                      playsInline
                      preload="metadata"
                    />
                  );
                }

                if (documentSrc) {
                  return (
                    <div className="locked-media-fallback">
                      <span className="locked-media-icon">📄</span>
                      {hasAccess ? (
                        <a href={documentSrc} target="_blank" rel="noreferrer">
                          Open Document
                        </a>
                      ) : (
                        <p>{isUnlockPending ? "Verifying payment..." : "Document available after unlock"}</p>
                      )}
                    </div>
                  );
                }

                return (
                  <div className="locked-media-fallback">
                    <p>No media attached</p>
                  </div>
                );
              })()}

              {!hasAccess && (
                <div className="locked-overlay">
                  <span className="lock-icon">{isUnlockPending ? "⏳" : "🔒"}</span>
                  <p className="lock-text">{isUnlockPending ? "Verifying payment..." : "Locked"}</p>
                </div>
              )}
            </div>
          ))}

        <div className="unlock-btn-wrapper">
          <button
            type="button"
            className="payment-button"
            // onClick={handlePayment}
            disabled={hasAccess || isUnlockPending}
            onClick={() => payment.setShowPopup(true)}
          >
            {hasAccess
              ? "Unlocked"
              : isUnlockPending
                ? "Verifying payment..."
              : unlockPrice > 0
                ? `Unlock for ₹${unlockPrice}`
                : "Unlock"}
          </button>
        </div>

        {payment.showPopup && (
          <div className="popup-overlay" onClick={() => payment.setShowPopup(false)}>
            <div className="popup-box" onClick={(e) => e.stopPropagation()}>
              <button
                type="button"
                className="popup-close-btn"
                aria-label="Close payment options"
                onClick={() => payment.setShowPopup(false)}
              >
                ×
              </button>
              <h2>Select Payment Method</h2>
              <div className="buyer-phone-section">
                <label htmlFor="buyer-phone-input">Enter your phone number</label>
                <input
                  id="buyer-phone-input"
                  type="tel"
                  value={buyerPhone}
                  inputMode="numeric"
                  maxLength={10}
                  placeholder="10-digit number"
                  onChange={(e) => {
                    const digits = e.target.value.replace(/\D/g, "").slice(0, 10);
                    setBuyerPhone(digits);
                    if (phoneError) {
                      setPhoneError("");
                    }
                  }}
                />
                {phoneError && <p className="buyer-phone-error">{phoneError}</p>}
              </div>

              <ul className="payment-list">
                {options.map((opt, index) => (
                  <li key={index} onClick={() => {
                    if (!selectedMessage) {
                      setPhoneError("Message not loaded yet. Please try again.");
                      return;
                    }
                    if (!isValidBuyerPhone) {
                      setPhoneError("Please enter a valid 10-digit phone number.");
                      return;
                    }
                    console.log("clicked: ", opt.name);
                    payment.startPayment(opt.name, selectedMessage.id, normalizedBuyerPhone);

                  }} className="payment-method">
                    <span>{opt.icon} <span className="icon">{opt.name}</span></span>

                    <span className="price"> Pay ₹{unlockPrice}</span>
                  </li>
                ))}
              </ul>


            </div>
          </div>
        )}
        {payment.showModal && (
          <PayModal
            method={payment.method}
            onClose={() => payment.setShowModal(false)}
            paymentSessionId={payment.paymentSessionId}
            orderId={payment.orderId}
            lockedMessageId={selectedMessageId}
            buyerPhone={normalizedBuyerPhone}
            ensurePaymentSession={payment.ensurePaymentSession}
            isCreatingSession={payment.isCreatingSession}
            cashfree={payment.cashfree}
            setHasAccess={payment.setHasAccess}
            verifyPayment={payment.verifyPayment}
          />
        )}
      </div>
    </>
  );
};


const PayModal = ({
  method,
  onClose,
  paymentSessionId,
  orderId,
  lockedMessageId,
  buyerPhone,
  ensurePaymentSession,
  isCreatingSession,
  cashfree,
  setHasAccess,
  verifyPayment,
}) => {
  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        {/* <h2>Pay with {method}</h2> */}
        {method === "UPI" &&
          <UpiPaymentModal paymentSessionId={paymentSessionId}
            orderId={orderId}
            lockedMessageId={lockedMessageId}
            buyerPhone={buyerPhone}
            ensurePaymentSession={ensurePaymentSession}
            isCreatingSession={isCreatingSession}
            cashfree={cashfree}
            onCloseModal={onClose}
            setHasAccess={setHasAccess}
            verifyPayment={verifyPayment}
          />
        }

        {/* Card UI */}
        {method === "Card" && (
          <CardComponent paymentSessionId={paymentSessionId}
            orderId={orderId}
            lockedMessageId={lockedMessageId}
            buyerPhone={buyerPhone}
            ensurePaymentSession={ensurePaymentSession}
            isCreatingSession={isCreatingSession}
            cashfree={cashfree}
            onCloseModal={onClose}
            setHasAccess={setHasAccess}
            verifyPayment={verifyPayment}
          />
        )}

        {/* Wallet UI */}
        {method === "Wallet" && (
          <WalletComponent paymentSessionId={paymentSessionId}
            orderId={orderId}
            lockedMessageId={lockedMessageId}
            buyerPhone={buyerPhone}
            ensurePaymentSession={ensurePaymentSession}
            isCreatingSession={isCreatingSession}
            cashfree={cashfree}
            onCloseModal={onClose}
            setHasAccess={setHasAccess}
            verifyPayment={verifyPayment}
          />
        )}
      </div>
    </div>
  );
};

export default LockedMessages;
