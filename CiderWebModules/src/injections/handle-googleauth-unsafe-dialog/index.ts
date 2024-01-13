window.onload = function () {
    if (window.location.pathname !== "/signin/oauth/danger")
        return;

    const advancedClass = "body > div.JhUD8d.HWKDRd > div.gvYJzb > a";
    const proceedSelector = "body > div.JhUD8d.HWKDRd > div:nth-child(6) > p:nth-child(2) > a";

    document.body.style.opacity = "0";

    const handleUnsafeDialog = () => {
        const proceedBtn = document.querySelector(proceedSelector) as HTMLElement;
        if (proceedBtn) {
            proceedBtn.click();
            return;
        }

        const advancedBtn = document.querySelector(advancedClass) as HTMLElement;
        if (advancedBtn)
            advancedBtn.click();
    };

    handleUnsafeDialog();
    setInterval(() => {
        handleUnsafeDialog();
    }, 20);
};
