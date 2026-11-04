
const sumar = (a, b) => {
    return a + b;
}

const restar = (a, b) => {

    return a - b;
}

const multiplicar = (a, b) => {
    return a * b;
}

const dividir = (a, b) => {
    if (b === 0) {
        throw new Error("No se puede dividir por cero");
    }
    return a / b;
}
