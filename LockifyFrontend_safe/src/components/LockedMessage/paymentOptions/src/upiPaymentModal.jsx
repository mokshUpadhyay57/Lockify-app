
import QrComponent from "./qrComponent"; // adjust path
import UpiComponent from "./upiComponent"
import "../css/upiPaymentModal.css"

const UpiPaymentModal = ({
    paymentSessionId,
    orderId,
    lockedMessageId,
    buyerPhone,
    ensurePaymentSession,
    isCreatingSession,
    cashfree,
    onCloseModal,
    setHasAccess,
    verifyPayment,
}) => {
    return (
        <div className="upi-modal">
            <QrComponent
                paymentSessionId={paymentSessionId}
                orderId={orderId}
                lockedMessageId={lockedMessageId}
                buyerPhone={buyerPhone}
                ensurePaymentSession={ensurePaymentSession}
                isCreatingSession={isCreatingSession}
                cashfree={cashfree}
                onCloseModal={onCloseModal}
                setHasAccess={setHasAccess}
                verifyPayment={verifyPayment}
            />

            {/* Divider */}
            <div className="upi-divider">
                <span>OR</span>
            </div>

            <UpiComponent
                paymentSessionId={paymentSessionId}
                orderId={orderId}
                lockedMessageId={lockedMessageId}
                buyerPhone={buyerPhone}
                ensurePaymentSession={ensurePaymentSession}
                isCreatingSession={isCreatingSession}
                cashfree={cashfree}
                onCloseModal={onCloseModal}
                setHasAccess={setHasAccess}
                verifyPayment={verifyPayment}
            />
        </div>
    );
};

export default UpiPaymentModal;
