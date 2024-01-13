import * as _ from "lodash-es";
import to from "await-to-js";
import {initializeApp} from "firebase/app";
import {signOut, getAuth, GoogleAuthProvider, OAuthProvider, signInWithPopup} from "firebase/auth";

window.sendNativeMessage = message => {
    alert(JSON.stringify(message));
};

enum SignInMethod {
    Apple = "/apple-auth",
    Google = "/google-auth",
    Azure = "/azure-auth"
}

(async () => {
    if (window.location.href === "about:blank")
        return;

    const signInMethod = window.location.pathname as SignInMethod;
    const firebaseConfig = {
        apiKey: "AIzaSyCYhHEBH-bkXBADELuwQX4NsoqaH7460pA",
        authDomain: "cider-collective.firebaseapp.com",
        databaseURL: "https://cider-collective-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "cider-collective",
        storageBucket: "cider-collective.appspot.com",
        messagingSenderId: "474254121753",
        appId: "1:474254121753:web:a6d9e3568656d192820388",
        measurementId: "G-Q3FL03JLBV"
    };

    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);
    auth.useDeviceLanguage();

    if (window.location.pathname === "/sign-out") {
        const [err] = await to(signOut(auth));
        if (err) {
            window.sendNativeMessage({
                action: "error",
                message: err.message
            });
        } else {
            window.localStorage.removeItem("user");
            window.sendNativeMessage({
                action: "sign-out-success"
            });
        }
        return;
    }

    let provider: OAuthProvider | GoogleAuthProvider;

    switch (signInMethod) {
        case SignInMethod.Apple:
            provider = new OAuthProvider("apple.com");
            provider.addScope("email");
            provider.addScope("name");
            break;

        case SignInMethod.Google:
            provider = new GoogleAuthProvider();
            provider.addScope("https://www.googleapis.com/auth/contacts.readonly");
            provider.setCustomParameters({
                prompt: "consent",
                access_type: "offline"
            });
            break;

        case SignInMethod.Azure:
            provider = new OAuthProvider("microsoft.com");
            provider.addScope("openid");
            provider.setCustomParameters({
                prompt: "consent",
                tenant: "358016f2-b726-4594-ae51-783a77899b42"
            });
            break;
    }

    const [err, result] = await to(signInWithPopup(auth, provider));
    if (err) {
        window.sendNativeMessage({
            action: "error",
            message: err.message
        });
        return;
    }

    // The signed-in user info.
    const user = result.user;

    // Apple credential
    const credential = OAuthProvider.credentialFromResult(result);
    const accessToken = credential?.accessToken;
    const idToken = credential?.idToken;

    window.sendNativeMessage({
        action: "auth-success",
        user: JSON.parse(JSON.stringify(user)),
        credential: JSON.parse(JSON.stringify(credential)),
        accessToken,
        idToken,
        signInMethod: _.toString(signInMethod)
    });
})();
