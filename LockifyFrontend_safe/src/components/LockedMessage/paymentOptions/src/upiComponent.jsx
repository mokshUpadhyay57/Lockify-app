import { useState, useEffect, useRef } from "react";
import "../css/qrComponent.css";
import { startCashfreeRedirectPayment } from "./paymentFlow";

const UpiComponent = ({
    paymentSessionId,
    lockedMessageId,
    buyerPhone,
    ensurePaymentSession,
    isCreatingSession,
    cashfree,
}) => {
    const [upiError, setUpiError] = useState("");
    const [message, setMessage] = useState("Click 'Pay via UPI' to start.");
    const [status, setStatus] = useState("idle");
    // idle | paying | verifying | success | error
    const upiInstanceRef = useRef(null);


    useEffect(() => {
        if (!cashfree) {
            console.warn("Cashfree not ready in QRDemo");
            return;
        }
        let opt = {
            values: {
                placeholder: "Enter UPI ID"
            }
        };
        upiInstanceRef.current = cashfree.create("upiCollect", opt);

        upiInstanceRef.current.mount("#upiCollect");

        upiInstanceRef.current.on("paymentrequested", () => {
            setStatus("paying");
            setMessage("Payment requested. Complete it in your UPI app.");
        });
    }, [cashfree]);


    // TODO: wire to your real collect flow (backend or cashfree.pay)
    const handlePayWithUpiId = async () => {

        try {
            setUpiError("");
            const { result } = await startCashfreeRedirectPayment({
                cashfree,
                paymentMethod: upiInstanceRef.current,
                paymentSessionId,
                ensurePaymentSession,
                lockedMessageId,
                buyerPhone,
            });
            console.log("Cashfree Upi-pay result:", result);
        } catch (err) {
            console.error("UPI collect error:", err);
            if (err?.code === "SESSION_UNAVAILABLE") {
                setUpiError("Could not create payment session. Please try again.");
                setStatus("error");
                return;
            }
            if (String(err).includes("not complete")) {
                setUpiError("Please enter a valid UPI ID before paying.");
            } else {
                setUpiError("Could not start UPI collect. Please try again.");
            }

            setStatus("error");
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
        <>
            <div className="upi-id-section">
                <div className="upi-id-header">
                    <span className="upi-id-title">Pay using UPI ID</span>
                    <span className="upi-id-subtitle">
                        Enter your UPI ID and approve the payment request
                    </span>
                </div>

                <div className="upi-id-row">
                    <div id="upiCollect" className="upi-input"></div>
                    <button
                        className="upi-id-btn"
                        onClick={handlePayWithUpiId}
                        disabled={isButtonDisabled}
                    >
                        {getButtonLabel()}
                    </button>
                </div>
                <p className="upi-status">{message}</p>
                {upiError && <p className="upi-error">{upiError}</p>}
            </div>
        </>
    );
};

export default UpiComponent;
