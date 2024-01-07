import {Spinner, SpinnerType} from "solid-spinner";
import {createEffect} from "solid-js";

export default function () {
    createEffect(() => {
    }, []);

    return (
        <div class={"flex flex-col space-y-5 h-screen items-center justify-center"}>
            <Spinner type={SpinnerType.tailSpin} />
            <h1>Authenticating with Apple Music</h1>
        </div>
    );
}
