function submitForm(e) {
    e.preventDefault();
    
    var myform = document.getElementById("entryCreateForm");
    
    var formData = new FormData(myform);
    let location = window.location.href;
    
    let errorElement = document.getElementById("errorText");
    let successElement = document.getElementById("savedText");
    
    errorElement.hidden = true;
    successElement.hidden = true;
    
    fetch(location, {
        method: "POST",
        body: formData,
    })
    .then((response) => {
        if (!response.ok) {
            throw new Error("network returns error");
        }
        return response.json();
    })
    .then((resp) => {
        console.log("Redirecting to: ", resp.redirect);
        window.location.href = resp.redirect;
    })
    .catch((error) => {
        // Handle error
        console.log("error ", error);
        errorElement.hidden = false;
        errorElement.innerText = `Failed to create: ${error}`;
    });
}

function updateSaveButton(form)
{
    const submitButton = form.querySelector('button');
    submitButton.disabled = true;
    
    const isFormValid = form.checkValidity();
    
    submitButton.disabled = !isFormValid;
}

document.addEventListener("DOMContentLoaded", (event) => {
    let form = document.getElementById("entryCreateForm");
    form.addEventListener("submit", submitForm);
    
    updateSaveButton(form);
    
    form.addEventListener('input', () => {
        updateSaveButton(form);
    });
});
