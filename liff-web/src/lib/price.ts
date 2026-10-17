export const priceText = (price: number): string => `NT$${Math.round(price).toLocaleString("en-US")}`;
