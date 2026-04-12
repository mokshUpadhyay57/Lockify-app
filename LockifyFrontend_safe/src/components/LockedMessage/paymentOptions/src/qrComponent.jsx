import { useState, useEffect } from "react";
import "../css/qrComponent.css";
import { startCashfreeRedirectPayment } from "./paymentFlow";

const QrComponent = ({
    paymentSessionId,
    lockedMessageId,
    buyerPhone,
    ensurePaymentSession,
    isCreatingSession,
    cashfree,
}) => {
    const [qr, setQr] = useState(null);
    const [message, setMessage] = useState("Click 'Pay via UPI' to start.");
    const [status, setStatus] = useState("idle");
    // idle | paying | verifying | success | error

    useEffect(() => {
        if (!cashfree) {
            console.warn("Cashfree not ready in QRDemo");
            return;
        }

        const qrInstance = cashfree.create("upiQr", {
            values: { size: "190px" },
        });

        qrInstance.mount("#qr");
        setQr(qrInstance);

        qrInstance.on("paymentrequested", () => {
            setStatus("paying");
            setMessage("Payment requested. Complete it in your UPI app.");
        });
    }, [cashfree]);

    const handlePayClick = async () => {
        if (!cashfree || !qr) {
            setMessage("Payment is not ready yet. Please wait a moment.");
            return;
        }

        // Allow retry only from idle or error
        if (!(status === "idle" || status === "error")) return;

        setStatus("paying");
        setMessage("Scan the QR and pay using any UPI app…");

        try {
            const { result } = await startCashfreeRedirectPayment({
                cashfree,
                paymentMethod: qr,
                paymentSessionId,
                ensurePaymentSession,
                lockedMessageId,
                buyerPhone,
            });

            console.log("Cashfree pay result:", result);
        } catch (err) {
            console.error("Payment start error:", err);
            setStatus("error");
            if (err?.code === "SESSION_UNAVAILABLE") {
                setMessage("Could not create payment session. Please try again.");
            } else {
                setMessage("Could not start payment. Please try again.");
            }
        }
    };

    const getButtonLabel = () => {
        switch (status) {
            case "idle":
            case "error":
                return "Pay via UPI";
            case "paying":
                return "Waiting for payment…";
            case "verifying":
                return "Verifying payment…";
            case "success":
                return "Payment Successful";
            default:
                return "Pay via UPI";
        }
    };

    const isButtonDisabled =
        isCreatingSession || status === "paying" || status === "verifying" || status === "success";

    return (
        <div className="upi-container">
            {/* Header */}
            <div className="upi-header">
                <span className="upi-title">Pay using UPI QR</span>
                <div className="upi-timer-pill">
                    <span className="upi-timer-icon">⏱</span>
                    <span className="upi-timer-text">11:40</span>
                </div>
            </div>
            <p className="upi-status">{message}</p>

            <div id="qr" className="upi-qr-mount"></div>

            <button
                className="upi-btn"
                disabled={isButtonDisabled}
                onClick={handlePayClick}>
                {getButtonLabel()}
            </button>
        </div>
    );
};

export default QrComponent;
