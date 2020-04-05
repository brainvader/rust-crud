document.addEventListener('DOMContentLoaded', () => {
    const app = Elm.Main.init({
        node: document.getElementById('elm')
    });

    app.ports.log.subscribe((message) => {
        console.log(`${message}  in JS`);
    });

    app.ports.ref.subscribe((selector) => {
        window.requestAnimationFrame(() => {
            const element = document.querySelector(selector);
            console.log(`${selector} is referenced`);
            element.addEventListener('click', () => {
                console.log(`${selector}`);
            });
        });
    });
})