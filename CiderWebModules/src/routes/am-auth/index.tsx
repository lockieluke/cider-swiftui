import {Spinner, SpinnerType} from "solid-spinner";
import {createEffect} from "solid-js";
import {render} from "solid-js/web";
import "@src/index.scss";

const App = () => {
    createEffect(() => {
        document.title = "Authenticating with Apple Music";
    }, []);

    return (
        <div class={"flex flex-col space-y-5 h-screen items-center justify-center"}>
            <Spinner type={SpinnerType.tailSpin} />
            <h1>Authenticating with Apple Music</h1>
        </div>
    );
};

render(App, document.getElementById("app")!);
