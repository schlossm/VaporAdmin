function deleteEntry(e) {
    console.log('Deleting!');
    e.preventDefault();
    
    const deleteModal = document.getElementById('deleteModal')
    const modalBodyInput = deleteModal.querySelector('.modal-body');
    
    const deleteButton = document.getElementById('confirmedDelete');
    const modelID = deleteButton.getAttribute('data-bs-modelID');
    const modelName = deleteButton.getAttribute('data-bs-modelName');
    
    let location = window.location.href;
    
    fetch(location + `/details/${modelID}`, {
        method: "DELETE",
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
        modalBodyInput.innerText = `Failed to delete: ${error}`;
    });
}

document.addEventListener("DOMContentLoaded", (event) => {
    const deleteModal = document.getElementById('deleteModal');
    const deleteButton = document.getElementById('confirmedDelete');
    deleteButton.addEventListener("click", deleteEntry);
    deleteModal.addEventListener('show.bs.modal', event => {
        // Button that triggered the modal
        const button = event.relatedTarget;
        // Extract info from data-bs-* attributes
        const modelID = button.getAttribute('data-bs-modelID');
        const modelName = button.getAttribute('data-bs-modelName');
        const modelDisplayName = button.getAttribute('data-bs-modelDisplayName');
        // If necessary, you could initiate an AJAX request here
        // and then do the updating in a callback.
        //
        // Update the modal's content.
        const modalBodyInput = deleteModal.querySelector('.modal-body');
        
        modalBodyInput.innerText = `This will delete ${modelName} entry "${modelDisplayName}"`;
        
        const deleteButton = document.getElementById('confirmedDelete');
        deleteButton.setAttribute('data-bs-modelID', modelID);
        deleteButton.setAttribute('data-bs-modelName', modelName);
    });
});
