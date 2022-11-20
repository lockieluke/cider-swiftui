export const waitUntil = (condition: boolean) => {
    return new Promise<void>(resolve => {
        let interval = setInterval(() => {
            if (!condition) {
                return
            }

            clearInterval(interval)
            resolve()
        }, 100)
    })
}
