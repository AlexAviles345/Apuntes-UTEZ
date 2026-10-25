const URL = "http://18.235.1.133:8089";

const findAll = async () => {
    let tbody = document.getElementById('tbody');
    let names = [];

    await fetch(`${URL}/people`, {
        method: 'GET',
        headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
    }).then(response => response.json()).then(result => {
        names = [ ...result.data ];
        let content = '';

        names.forEach(itm => content += `<tr>
                                            <td>${itm.name}</td>
                                        </tr>`);

        tbody.innerHTML = content;
    })
    .catch(console.log);
}

(() => {
    findAll();
})()

const savePerson = async () => {
    const person = {
        name: document.getElementById('name').value
    }

    await fetch(`${URL}/people`, {
        method: 'POST',
        headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        body: JSON.stringify(person)
    }).then(response => response.json())
    .then((result) => {
        console.log(result);
        findAll();
    })
    .catch(console.log);
}