import { createFileRoute } from "@tanstack/react-router";
import { Forge } from "@/components/forge";

export const Route = createFileRoute("/")({ component: Home });

function Home() {
  return <Forge />;
}
