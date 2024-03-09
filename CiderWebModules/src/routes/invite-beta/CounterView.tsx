import {JSXElement, mergeProps} from "solid-js";

export default function CounterView(props: {
    children?: JSXElement;
    label?: string;
}) {
    const {children, label} = mergeProps({
        children: null,
        label: "Counter"
    }, props);

    return (
        <div class={"shadow-lg transform-gpu transition-transform active:scale-[98%] hover:-translate-y-2 bg-gradient-to-tr from-gray-400 via-gray-500 to-zinc-500 p-[2px] rounded-md opacity-90 backdrop-blur-xl"}>
            <div class={"flex flex-col items-center justify-center bg-gradient-to-br from-gray-600 via-gray-700 to-zinc-600 p-3 text-white rounded-md"}>
                <span class={"font-bold"}>{label}</span>
                <span class={"text-2xl"}>{children}</span>
            </div>
        </div>
    );
}
