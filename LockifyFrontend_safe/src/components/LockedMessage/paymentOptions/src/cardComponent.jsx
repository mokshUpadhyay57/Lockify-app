import { useState, useEffect, useRef } from "react";
import "../css/cardComponent.css";
import { startCashfreeRedirectPayment } from "./paymentFlow";

export const CardComponent = ({
    paymentSessionId,
    lockedMessageId,
    buyerPhone,
    ensurePaymentSession,
    isCreatingSession,
    cashfree,
}) => {

    const [status, setStatus] = useState("idle");
    const [message, setMessage] = useState("");
    const [payDisabled, setPayDisabled] = useState(true);

    // DOM refs
    const cardNumberRef = useRef(null);
    const cardExpiryRef = useRef(null);
    const cardCvvRef = useRef(null);
    const cardHolderRef = useRef(null);
    const saveRef = useRef(null);
    const elementsRef = useRef({});

    useEffect(() => {
        if (!cashfree) {
            console.warn("Cashfree not ready in QRDemo");
            return;
        }

        const cardNumber = cashfree.create("cardNumber", {
            values: { placeholder: "Enter Card Number" },
        });

        const cardCvv = cashfree.create("cardCvv");
        const cardHolder = cashfree.create("cardHolder");
        const cardExpiry = cashfree.create("cardExpiry");
        const save = cashfree.create("savePaymentInstrument", {
            values: { label: "Save Card for later" },
        });

        // Cashfree element refs
        cardNumber.mount(cardNumberRef.current);
        cardExpiry.mount(cardExpiryRef.current);
        cardCvv.mount(cardCvvRef.current);
        cardHolder.mount(cardHolderRef.current);
        save.mount(saveRef.current);

        elementsRef.current = {
            cardNumber,
            cardExpiry,
            cardCvv,
            cardHolder,
            save,
        };

        const toggleButton = () => {
            const { cardNumber, cardExpiry, cardCvv, cardHolder } = elementsRef.current;

            setPayDisabled(
                !(
                    cardNumber.isComplete() &&
                    cardExpiry.isComplete() &&
                    cardCvv.isComplete() &&
                    cardHolder.isComplete()
                )
            );
        };

        cardNumber.on("change", toggleButton);
        cardExpiry.on("change", toggleButton);
        cardCvv.on("change", toggleButton);
        cardHolder.on("change", toggleButton);

        return () => {
            cardNumber.unmount();
            cardExpiry.unmount();
            cardCvv.unmount();
            cardHolder.unmount();
            save.unmount();
        };


    }, [cashfree]);

    const handlePayClick = async () => {
        setStatus("paying");
        setMessage("Processing card payment...");
        console.log("Attempting card payment with session ID:", paymentSessionId);
        try {
            const { cardNumber, save } = elementsRef.current;
            const { result } = await startCashfreeRedirectPayment({
                cashfree,
                paymentMethod: cardNumber,
                paymentSessionId,
                ensurePaymentSession,
                lockedMessageId,
                buyerPhone,
                extraOptions: {
                    savePaymentInstrument: save,
                },
            });
            console.log("Payment completed");
            console.log("Cashfree pay result:", result);

            if (result?.error) {
                setStatus("error");
                setMessage(result.error.message);
                return;
            }
        } catch (err) {
            console.error("Payment start error:", err);
            if (err?.code === "SESSION_UNAVAILABLE") {
                setMessage("Could not create payment session. Please try again.");
            } else {
                setMessage("Payment failed. Please try again.");
            }
            setStatus("error");
        }
    };


    const isButtonDisabled = isCreatingSession || payDisabled || status === "paying" || status === "verifying" || status === "success";
    const getButtonLabel = () => {
        switch (status) {
            case "idle":
            case "error": return "Pay with Card";
            case "paying": return "Processing…";
            case "verifying": return "Verifying payment…";
            case "success": return "Payment Successful";
            default: return "Pay with Card";
        }
    };
    return (
        <div className="card-container">
            {/* Header */}
            <div className="field" ref={cardNumberRef} />

            <div className="field" ref={cardHolderRef} />

            <div className="row">
                <div className="field half" ref={cardExpiryRef} />
                <div className="field half" ref={cardCvvRef} />
            </div>

            <div className="save-row" ref={saveRef} />

            {message && <p>{message}</p>}

            <button className="card-btn" disabled={isButtonDisabled} onClick={handlePayClick}>
                {getButtonLabel()}
            </button>
        </div>
    );
};
