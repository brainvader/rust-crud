document.addEventListener('DOMContentLoaded', () => {
    const app = Elm.Main.init({
        node: document.getElementById('elm')
    });

    app.ports.log.subscribe((message) => {
        console.log(`${message} from Elm`);
    });
})
