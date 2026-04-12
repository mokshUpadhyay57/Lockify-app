import React, { useEffect, useRef, useState, useCallback } from "react";
import "../css/walletComponent.css"
import { startCashfreeRedirectPayment } from "./paymentFlow";

export const WalletComponent = ({
	cashfree,
	paymentSessionId,
	lockedMessageId,
	buyerPhone = "",
	ensurePaymentSession,
	isCreatingSession,
}) => {
	const [message, setMessage] = useState("");
	const walletRefs = useRef({});
	const walletComponents = useRef({});

	const WALLET_PROVIDERS = React.useMemo(() => ["paytm", "phonepe", "jio", "mobikwik"], []);

	const initPay = useCallback(async (provider) => {
		const comp = walletComponents.current[provider];
		if (!comp || isCreatingSession) return;

		// 🔑 mark wallet payment started
		sessionStorage.setItem("WALLET_PAYMENT_STARTED", "true");

		setMessage("Redirecting to wallet…");

		try {
			await startCashfreeRedirectPayment({
				cashfree,
				paymentMethod: comp,
				paymentSessionId,
				ensurePaymentSession,
				lockedMessageId,
				buyerPhone,
			});
		} catch (err) {
			console.error(err);
			if (err?.code === "SESSION_UNAVAILABLE") {
				setMessage("Could not create payment session. Please try again.");
			} else {
				setMessage("Unable to start wallet payment");
			}
		}
	}, [buyerPhone, cashfree, ensurePaymentSession, isCreatingSession, lockedMessageId, paymentSessionId]);

	useEffect(() => {
		if (!cashfree) return;

		const style = {
			base: {
				fontSize: "30px",
			},
		};

		WALLET_PROVIDERS.forEach((provider) => {
			const component = cashfree.create("wallet", {
				values: {
					provider,
					phone: buyerPhone,
					buttonIcon: true
				},
				style,
			});

			component.mount(walletRefs.current[provider]);
			component.on("click", () => {
				initPay(provider);
			});
			walletComponents.current[provider] = component;
		});

		const currentWalletComponents = { ...walletComponents.current };

		return () => {
			Object.values(currentWalletComponents).forEach((comp) =>
				comp.unmount()
			);
		};
	}, [WALLET_PROVIDERS, buyerPhone, cashfree, initPay]);

	return (
		<div className="wallet-container">
			<div className="wallet-grid">
				{WALLET_PROVIDERS.map((provider) => (
					<div
						key={provider}
						className="wallet-item"
					>
						<div
							className="wallet-icon"
							ref={(el) => (walletRefs.current[provider] = el)}
						/>
						<span className="wallet-label">{provider.toUpperCase()}</span>
					</div>
				))}
			</div>

			{message && <p className="wallet-message">{message}</p>}
		</div>
	);
};
