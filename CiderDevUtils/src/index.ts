import fastify from "fastify";
import shelljs from 'shelljs';

declare global {
    namespace NodeJS {
        interface ProcessEnv {
            PORT: number;
            CWD: string;
        }
    }
}

const app = fastify();
const cwd = process.env.CWD ?? process.cwd();
const taskBin = await shelljs.which('task');

app.get<{
    Querystring: {
        task: string;
    }
}>('/perform-task', (request, reply) => {
    const task = request.query.task;
    const proc = shelljs.exec(`${taskBin} ${task}`, {
        cwd,
        silent: true
    });
    const now = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '')
    console.log(`${now} - ${task} is performed with exit code ${proc.code}`);

    const output = proc.stdout + proc.stderr;
    reply.status(proc.code == 0 ? 200 : 500).send(output);
});

app.listen({
    port: 2345 || process.env.PORT
}, (err, addr) => {
    if (err) {
        console.error(err);
        process.exit(1);
    }
    console.log(`CiderDevServer listening on ${addr}`);
});
