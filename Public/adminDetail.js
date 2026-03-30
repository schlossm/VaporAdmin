function submitForm(e) {
    e.preventDefault();
    
    var myform = document.getElementById("entryDetailForm");
    
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
        return "ok";
    })
    .then((resp) => {
        successElement.hidden = false;
    })
    .catch((error) => {
        // Handle error
        errorElement.hidden = false;
        errorElement.innerText = `Failed to save: ${error}`;
    });
}

function updateSaveButton(form, originalFormData)
{
    const submitButton = form.querySelector('button');
    submitButton.disabled = true;
    
    const isFormValid = form.checkValidity();
    
    const _newFormData = new FormData(form).values();
    let newFormData = [];
    for (const value of _newFormData) {
        newFormData.push(value);
    }
    
    const isFormChanged = originalFormData.toString() !== newFormData.toString();
    
    submitButton.disabled = !isFormValid || !isFormChanged;
}

document.addEventListener("DOMContentLoaded", (event) => {
    let form = document.getElementById("entryDetailForm");
    form.addEventListener("submit", submitForm);
    
    const _originalFormData = new FormData(form).values();
    let originalFormData = [];
    for (const value of _originalFormData) {
        originalFormData.push(value);
    }
    
    updateSaveButton(form, originalFormData);
    
    form.addEventListener('input', () => {
        updateSaveButton(form, originalFormData);
    });
});
