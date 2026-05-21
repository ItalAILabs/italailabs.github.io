const form = document.getElementById("mailForm");
const errorMessage = document.getElementById("errorMessage");
const successMessage = document.getElementById("successMessage");

form.addEventListener("submit", async (e) => {
e.preventDefault();

const formData = new FormData(form);

try {
    const response = await fetch(
    "https://formspree.io/f/mwpejjrb",
    {
        method: "POST",
        body: formData,
        headers: { Accept: "application/json" },
    }
    );

    if (response.ok) {
    form.reset();
    successMessage.style.display = "block";
    errorMessage.style.display = "none";
    } else {
    throw new Error("Form submission failed");
    }
} catch (error) {
    console.error("Error:", error);
    errorMessage.style.display = "block";
    successMessage.style.display = "none";
}
});
