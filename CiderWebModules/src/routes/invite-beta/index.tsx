/* @refresh reload */
import {render, Show} from "solid-js/web";

import "@src/index.scss";
import {z, ZodError} from "zod";
import dayjs from "dayjs";
import objectSupport from "dayjs/plugin/objectSupport";
import {IS_DEV} from "@src/lib/dev.ts";
import {Input} from "@src/components/ui/input.tsx";
import {Button} from "@src/components/ui/button.tsx";
import {IconSend} from "@tabler/icons-solidjs";
import {BackgroundGradientAnimation} from "@src/components/ui/background-gradient-animation.tsx";

import "@src/overscroll-prevent.scss";
import CounterView from "@src/routes/invite-beta/CounterView.tsx";
import {
    AlertDialog,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogTitle
} from "@src/components/ui/alert-dialog.tsx";
import {createEffect, createSignal} from "solid-js";
import {ColorModeProvider, ColorModeScript} from "@kobalte/core";
import {TransitionGroup} from "solid-transition-group";

dayjs.extend(objectSupport);

declare global {
    interface Window {
        triggerShowAlreadyInvitedDialog: () => void;
        doneSubmitting: () => void;
    }
}

const App = () => {
    let emailRef: HTMLInputElement | null = null;

    const [showInvalidEmailDialog, setShowInvalidEmailDialog] = createSignal(false);
    const [showAlreadyInvitedDialog, setShowAlreadyInvitedDialog] = createSignal(false);
    const [showSubmittedScreen, setShowSubmittedScreen] = createSignal(false);

    const onSubmit = async () => {
        try {
            const email = await z.string().email("Invalid Email").parseAsync(emailRef?.value);

            window.webkit.messageHandlers.ciderkit.postMessage({
                event: "add-invite-beta",
                email
            });

            if (emailRef)
                emailRef.value = "";
        } catch (err) {
            if (err instanceof ZodError && err.errors[0].message === "Invalid Email") {
                setShowInvalidEmailDialog(true);
            }
        }
    };

    createEffect(() => {
        window.triggerShowAlreadyInvitedDialog = () => {
            setShowAlreadyInvitedDialog(true);
        };

        window.doneSubmitting = () => {
            setShowSubmittedScreen(true);
        };
    }, []);

    return (
        <>
            <ColorModeScript storageType={"localStorage"} />
            <ColorModeProvider>
                <AlertDialog open={showInvalidEmailDialog()} onOpenChange={open => {
                    setShowInvalidEmailDialog(open);
                    if (!open)
                        emailRef?.focus();
                }}>
                    <AlertDialogContent>
                        <AlertDialogTitle>Invalid Email</AlertDialogTitle>
                        <AlertDialogDescription>
                            Please enter a valid email address
                        </AlertDialogDescription>
                    </AlertDialogContent>
                </AlertDialog>
                <AlertDialog open={showAlreadyInvitedDialog()} onOpenChange={open => {
                    setShowAlreadyInvitedDialog(open);
                    if (!open)
                        emailRef?.focus();
                }}>
                    <AlertDialogContent>
                        <AlertDialogTitle>Already Invited</AlertDialogTitle>
                        <AlertDialogDescription>
                            You have already been added to the public beta
                        </AlertDialogDescription>
                    </AlertDialogContent>
                </AlertDialog>
                <BackgroundGradientAnimation containerclass={"absolute pointer-events-none backdrop-blur-md transform-gpu"} />
                <div class={"absolute flex flex-col h-dvh px-[32%] items-center justify-center text-center text-white"}
                     onContextMenu={e => {
                         if (!IS_DEV)
                             e.preventDefault();
                     }}>
                    <Show when={!showSubmittedScreen()}>
                        <div class={"flex items-center justify-center space-x-5 my-5"}>
                            <CounterView label={"Commits"}>800+</CounterView>
                            <CounterView label={"Development Days"}>{dayjs().diff({
                                day: 26,
                                month: 7,
                                year: 2022
                            }, "days")}</CounterView>
                        </div>
                        <h1 class={"text-2xl font-semibold my-3"}><strong>Cider for macOS</strong> is going Public Beta</h1>
                        <span class={"text-sm"}>
          This version of <strong>Cider for macOS</strong> will be phasing out soon and will be replaced by an all new public beta.
                            &nbsp;&nbsp;<strong>Cider for macOS</strong> will be a separate purchase from mainline Cider and a 30% off discount is offered for being an alpha tester for many moons.
      </span>
                        <div class={"flex items-center space-x-5 my-7 w-[80%]"}>
                            <Input autofocus ref={ref => (emailRef = ref)} class={"shadow-sm"} type={"email"} placeholder={"Enter your email"} onKeyPress={async event => {
                                if (event.key === "Enter")
                                    await onSubmit();
                            }} />
                            <Button class={"cursor-default shadow-md transform-gpu transition-transform active:scale-[98%]"} onClick={onSubmit}><IconSend size={15}/></Button>
                        </div>

                        <a href={"#"} class={"text-sm hover:text-muted-foreground active:text-zinc-600"} onClick={event => {
                            event.preventDefault();

                            window.webkit.messageHandlers.ciderkit.postMessage({
                                event: "exit-invite-beta"
                            });
                        }}>Not Now</a>
                    </Show>
                    <TransitionGroup onEnter={(element, done) => {
                        const animation = element.animate([{ opacity: 0 }, { opacity: 1 }], {
                            easing: "ease-in",
                            duration: 300
                        });

                        animation.finished.then(done);
                    }}>
                        <Show when={showSubmittedScreen()}>
                            <h1 class={"text-2xl font-semibold my-3"}>You're in!</h1>
                            <span class={"text-sm"}>You have been added to the <strong>Cider for macOS</strong> public beta waitlist, you will be soon sent an email</span>
                            <Button class={"my-3 cursor-default shadow-md transform-gpu transition-transform active:scale-[98%]"} onClick={() => {
                                window.webkit.messageHandlers.ciderkit.postMessage({
                                    event: "exit-invite-beta"
                                });
                            }}>Done</Button>
                        </Show>
                    </TransitionGroup>
                </div>
                <Show when={IS_DEV && !showSubmittedScreen()}>
                    <Button class={"absolute bottom-0 right-0 m-5 cursor-default"} onClick={() => setShowSubmittedScreen(true)}>Skip to Submitted</Button>
                </Show>
            </ColorModeProvider>
        </>
    );
};

render(App, document.getElementById("app")!);
