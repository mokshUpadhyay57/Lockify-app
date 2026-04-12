import { useRef, useState, useCallback } from "react";
import { getDownloadURL, ref } from "firebase/storage";

const CACHE_KEY = "locked_image_cache_v1";
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24h

function loadCache() {
    try {
        const data = JSON.parse(localStorage.getItem(CACHE_KEY)) || {};
        const now = Date.now();

        for (const key in data) {
            if (!data[key] || now - data[key].timestamp > CACHE_TTL) {
                delete data[key];
            }
        }
        return data;
    } catch {
        return {};
    }
}

function saveCache(cache) {
    try {
        localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
    } catch {
        console.warn("Cache save failed");
    }
}

export function useImageCache(storage) {
    const cacheRef = useRef(loadCache());
    const [imageUrls, setImageUrls] = useState({});

    const fetchImage = useCallback(async (docId, imageUrl, alive = true) => {
        const rawUrl = typeof imageUrl === "string" ? imageUrl.trim() : "";
        if (!rawUrl) return null;

        const cached = cacheRef.current[rawUrl];

        if (cached) {
            if (alive) {
                setImageUrls(prev => ({ ...prev, [docId]: cached.url }));
            }
            return cached.url;
        }

        try {
            let url = rawUrl;
            const isDirectHttpUrl = /^https?:\/\//i.test(rawUrl);
            if (!isDirectHttpUrl) {
                const imageRef = ref(storage, rawUrl);
                url = await getDownloadURL(imageRef);
            }

            if (!alive) return null;

            cacheRef.current[rawUrl] = { url, timestamp: Date.now() };
            saveCache(cacheRef.current);

            setImageUrls(prev => ({ ...prev, [docId]: url }));
            return url;
        } catch (err) {
            console.error("Image load failed:", err);
            return null;
        }
    }, [storage]);

    return { imageUrls, fetchImage };
}
