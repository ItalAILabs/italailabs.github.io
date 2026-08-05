const UTM_KEYS = ["utm_source", "utm_medium", "utm_campaign"];
const params = new URLSearchParams(window.location.search);

const captured = {};
UTM_KEYS.forEach((key) => {
  const value = params.get(key);
  if (value) captured[key] = value;
});

if (Object.keys(captured).length) {
  UTM_KEYS.forEach((key) => {
    if (captured[key]) localStorage.setItem(key, captured[key]);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  UTM_KEYS.forEach((key) => {
    const field = document.querySelector(`input[name="${key}"]`);
    if (field) field.value = localStorage.getItem(key) || "";
  });
});
