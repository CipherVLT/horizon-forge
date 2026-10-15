import { useState } from "react";
import { Download, Copy, Check } from "lucide-react";
import { EH_REF, recipeFiles } from "@/lib/recipe";

const layers = [
  {
    name: "Fedora bootc",
    detail: "The immutable base Universal Blue already tracks.",
  },
  {
    name: "Bazzite",
    detail: "Gaming stack, kernel, Steam, Gamescope, drivers. Left intact.",
  },
  {
    name: "Hyprland",
    detail: "A login session next to Plasma, not a replacement of KDE.",
  },
  {
    name: "Event Horizon",
    detail: "ryzendew's shell. Dock, panel, and the rest, started with the session.",
  },
];

const keys = [
  ["Super + Enter", "kitty"],
  ["Super + Space", "fuzzel"],
  ["Super + Q", "close window"],
  ["Super + M", "leave Hyprland"],
  ["Super + arrows", "move focus"],
  ["Super + 1–9", "workspace"],
];

const cookSteps = {
  nvidia: {
    tag: "bazzite-horizon-nvidia",
    menu: "Bazzite Horizon NVIDIA",
    cook: "just cook-iso nvidia",
    pull: "just cook-iso nvidia pull",
    push: "podman push localhost/bazzite-horizon-nvidia:latest ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest",
    switchCmd: "sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest",
  },
  amd: {
    tag: "bazzite-horizon",
    menu: "Bazzite Horizon",
    cook: "just cook-iso amd",
    pull: "just cook-iso amd pull",
    push: "podman push localhost/bazzite-horizon:latest ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest",
    switchCmd: "sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest",
  },
} as const;

export function Forge() {
  const [active, setActive] = useState(recipeFiles[0].id);
  const [copied, setCopied] = useState(false);
  const [gpu, setGpu] = useState<keyof typeof cookSteps>("nvidia");
  const file = recipeFiles.find((item) => item.id === active) ?? recipeFiles[0];
  const cook = cookSteps[gpu];

  async function copyFile() {
    try {
      await navigator.clipboard.writeText(file.body);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      setCopied(false);
    }
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-col gap-10 px-5 py-10 sm:py-14">
      <header className="flex flex-col gap-4">
        <p className="text-sm font-medium tracking-wide text-accent uppercase">
          Universal Blue image
        </p>
        <h1 className="font-display text-5xl leading-none text-fg sm:text-6xl">
          Horizon Forge
        </h1>
        <p className="max-w-xl text-lg text-muted">
          A Bazzite image with Event Horizon as the shell. Same bootc idea as
          theblackdon's KineticOS, pointed at ryzendew's desktop instead of KineticWE.
        </p>
        <div className="h-px w-16 bg-accent" />
      </header>

      <section className="grid gap-3 sm:grid-cols-2" aria-label="Image variants">
        <article className="flex flex-col gap-2 rounded-card border border-line bg-surface p-5">
          <h2 className="font-display text-2xl text-fg">AMD and Intel</h2>
          <p className="font-mono text-sm text-accent">bazzite-horizon</p>
          <p className="text-sm text-muted">
            Built from bazzite:stable. Use this tag on machines without an NVIDIA GPU.
          </p>
        </article>
        <article className="flex flex-col gap-2 rounded-card border border-line bg-surface p-5">
          <h2 className="font-display text-2xl text-fg">NVIDIA open</h2>
          <p className="font-mono text-sm text-accent">bazzite-horizon-nvidia</p>
          <p className="text-sm text-muted">
            Built from bazzite-nvidia-open. This is the Blackwell image, including a 5070 Ti.
            Not the older proprietary driver tag.
          </p>
        </article>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">Stack</h2>
        <ol className="flex flex-col">
          {layers.map((layer, index) => (
            <li
              key={layer.name}
              className="grid grid-cols-[2.5rem_1fr] gap-3 border-t border-line py-4"
            >
              <span className="font-mono text-sm text-accent">0{index + 1}</span>
              <div>
                <p className="font-medium text-fg">{layer.name}</p>
                <p className="text-sm text-muted">{layer.detail}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">What was revised</h2>
        <ul className="flex flex-col gap-3">
          <li className="rounded-card border border-line bg-surface p-5">
            <p className="font-medium text-fg">Portable shell, pinned commit</p>
            <p className="mt-1 text-sm text-muted">
              Fedora.md's <span className="text-fg">sudo just install</span> compiles with{" "}
              <span className="text-fg">-Dnative_march=true</span>. That binary matches the
              GitHub runner, then faults on other CPUs. The image build pins{" "}
              <span className="font-mono text-xs text-accent">{EH_REF.slice(0, 12)}</span> and
              forces a generic release build. The compiler stays out of the final image.
            </p>
          </li>
          <li className="rounded-card border border-line bg-surface p-5">
            <p className="font-medium text-fg">One Containerfile, two Bazzite bases</p>
            <p className="mt-1 text-sm text-muted">
              image-template hard-codes a single FROM line. This one takes BASE_IMAGE, the
              same split dcli-bootc puts under base_images. Plasma is still installed.
            </p>
          </li>
          <li className="rounded-card border border-line bg-surface p-5">
            <p className="font-medium text-fg">A session, not a second distro</p>
            <p className="mt-1 text-sm text-muted">
              The login screen gains an Event Horizon entry. First login seeds Hyprland only
              if you don't already have a config. KDE remains the fallback.
            </p>
          </li>
        </ul>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">Seeded keys</h2>
        <div className="overflow-hidden rounded-card border border-line">
          {keys.map(([binding, action]) => (
            <div
              key={binding}
              className="grid grid-cols-2 gap-3 border-t border-line px-4 py-3 first:border-t-0"
            >
              <span className="text-sm text-fg">{binding}</span>
              <span className="text-sm text-muted">{action}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="flex flex-col gap-4">
        <div className="flex items-end justify-between gap-3">
          <h2 className="font-display text-3xl text-fg">Recipe</h2>
          <button
            type="button"
            onClick={copyFile}
            className="inline-flex min-h-11 items-center gap-2 rounded-card border border-line bg-raised px-4 text-sm text-fg"
          >
            {copied ? <Check className="size-4 text-accent" /> : <Copy className="size-4" />}
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
        <div
          role="tablist"
          aria-label="Recipe files"
          className="flex gap-2 overflow-x-auto pb-1"
        >
          {recipeFiles.map((item) => {
            const selected = item.id === file.id;
            return (
              <button
                key={item.id}
                type="button"
                role="tab"
                aria-selected={selected}
                onClick={() => {
                  setActive(item.id);
                  setCopied(false);
                }}
                className={
                  selected
                    ? "min-h-11 shrink-0 rounded-card bg-accent px-4 text-sm font-medium text-accent-ink"
                    : "min-h-11 shrink-0 rounded-card border border-line bg-surface px-4 text-sm text-muted"
                }
              >
                {item.label}
              </button>
            );
          })}
        </div>
        <pre className="max-h-96 overflow-auto rounded-card border border-line bg-raised p-4 font-mono text-xs leading-relaxed text-fg">
          {file.body}
        </pre>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">Still bootc</h2>
        <p className="text-sm text-muted">
          The system you boot every day is a bootc image, the same kind Bazzite already is.
          Pick the GPU once. That choice is the only difference between the two commands.
        </p>
        <div className="flex gap-2" role="tablist" aria-label="Which GPU the ISO is for">
          <button
            type="button"
            role="tab"
            aria-selected={gpu === "nvidia"}
            onClick={() => setGpu("nvidia")}
            className={
              gpu === "nvidia"
                ? "min-h-11 rounded-card bg-accent px-4 text-sm font-medium text-accent-ink"
                : "min-h-11 rounded-card border border-line bg-surface px-4 text-sm text-muted"
            }
          >
            NVIDIA
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={gpu === "amd"}
            onClick={() => setGpu("amd")}
            className={
              gpu === "amd"
                ? "min-h-11 rounded-card bg-accent px-4 text-sm font-medium text-accent-ink"
                : "min-h-11 rounded-card border border-line bg-surface px-4 text-sm text-muted"
            }
          >
            AMD / Intel
          </button>
        </div>
        <article className="flex flex-col gap-2 rounded-card border border-line bg-surface p-5">
          <h3 className="font-medium text-fg">Already on Bazzite, or any bootc system</h3>
          <p className="text-sm text-muted">
            This is the whole install. No USB, no ISO, no installer. Reboot when it tells you to.
            Do not run the other GPU's command.
          </p>
          <p className="break-all font-mono text-xs text-fg">{cook.switchCmd}</p>
        </article>
        <article className="flex flex-col gap-2 rounded-card border border-line bg-surface p-5">
          <h3 className="font-medium text-fg">Blank disk, so you need a USB</h3>
          <p className="text-sm text-muted">
            The USB uses Fedora's installer once, only to copy this same bootc image onto the
            disk. That installer is named Anaconda. It is not the operating system, and you
            do not configure it. When the copy finishes it runs bootc switch for you, so the
            disk tracks your GitHub image. After that, updates are:
          </p>
          <p className="font-mono text-xs text-fg">sudo bootc upgrade</p>
        </article>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">Cook the ISO</h2>
        <p className="text-sm text-muted">
          Skip this section if the machine already runs Bazzite. Do not download a Bazzite
          ISO from the website. Those are stock installers. This recipe starts from the
          Bazzite container, which already includes Plasma.
        </p>
        <ol className="flex flex-col gap-4">
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">1</span>
            <p className="text-sm text-muted">
              Download the recipe. New GitHub repository, push the files, turn Actions on.
              Set REPO_ORGANIZATION in image-template.env to that account.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">2</span>
            <p className="text-sm text-muted">
              Push to main and wait until Build container image is green. It compiles the
              shell twice, once for each GPU.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">3</span>
            <p className="text-sm text-muted">
              Actions, Build disk images, Run workflow. Choose{" "}
              <span className="font-mono text-xs text-fg">{cook.tag}</span>. Leave the
              platform on amd64. Download the anaconda-iso artifact and unzip install.iso.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">4</span>
            <p className="text-sm text-muted">
              Flash the USB with Fedora Media Writer or KDE ISO Image Writer. On Arch,
              point dd at the USB, not the system disk.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">5</span>
            <p className="text-sm text-muted">
              Firmware: UEFI, Secure Boot off. The USB menu is still GRUB. That is only
              the installer. After install, systemd-boot lists{" "}
              <span className="text-fg">{cook.menu}</span>. If the first reboot is still
              GRUB, boot once and reboot. Then pick Event Horizon at the login screen.
              Give the EFI partition about 2 GiB if the disk editor lets you.
            </p>
          </li>
        </ol>
        <div className="rounded-card border border-line bg-surface p-5 font-mono text-xs leading-relaxed text-fg">
          <p className="text-muted">
            On this computer, from the recipe folder, instead of the disk-image workflow:
          </p>
          <p className="mt-2">{cook.cook}</p>
          <p className="mt-2 break-all">{cook.push}</p>
          <p className="mt-2 text-muted">If the container is already on ghcr, skip the compile:</p>
          <p className="mt-2">{cook.pull}</p>
        </div>
        <p className="text-sm text-muted">
          Push the tag before you boot the USB. The installer retargets the disk at that
          registry image, and it stops if the tag is missing. just cook-iso is the command
          that applies the systemd-boot kickstart. The older just build-iso name does not.
        </p>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-3xl text-fg">Publish</h2>
        <ol className="flex flex-col gap-4">
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">1</span>
            <p className="text-sm text-muted">
              Download the recipe and push it to a new GitHub repository. Turn Actions on.
              Set REPO_ORGANIZATION in image-template.env to that account.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">2</span>
            <p className="text-sm text-muted">
              Push to main. The container workflow publishes both tags. The first run pulls
              Bazzite and compiles the shell, so it takes a while. Signing is optional until
              you add a SIGNING_SECRET.
            </p>
          </li>
          <li className="flex gap-3">
            <span className="font-mono text-sm text-accent">3</span>
            <p className="text-sm text-muted">
              On a machine already running Bazzite, run the bootc switch command above and
              reboot. Use the ISO only for a blank disk. Then pick Event Horizon at the
              login screen. Later updates are sudo bootc upgrade.
            </p>
          </li>
        </ol>
        <div className="rounded-card border border-line bg-surface p-5 font-mono text-xs leading-relaxed text-fg">
          <p>sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest</p>
          <p className="mt-2 text-muted">
            sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest
          </p>
        </div>
        <a
          href="/bazzite-horizon.zip"
          download
          className="inline-flex min-h-11 items-center justify-center gap-2 rounded-card bg-accent px-5 text-sm font-medium text-accent-ink"
        >
          <Download className="size-4" />
          Download the recipe
        </a>
        <p className="text-sm text-muted">
          The ISO is built by GitHub after the container image exists. This page is the
          blueprint and the files, not a flashed installer.
        </p>
      </section>

      <footer className="border-t border-line pt-6 text-sm text-muted">
        <p>
          Shell docs:{" "}
          <a
            className="text-fg underline decoration-line underline-offset-4"
            href="https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell/blob/main/Docs/Fedora.md"
          >
            Event Horizon on Fedora
          </a>
          . Image scaffold:{" "}
          <a
            className="text-fg underline decoration-line underline-offset-4"
            href="https://github.com/ublue-os/image-template"
          >
            ublue-os/image-template
          </a>
          . Layout reference:{" "}
          <a
            className="text-fg underline decoration-line underline-offset-4"
            href="https://gitlab.com/theblackdon/dcli-bootc"
          >
            dcli-bootc
          </a>
          .
        </p>
      </footer>
    </main>
  );
}
