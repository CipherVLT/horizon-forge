import containerfile from "../../bazzite-horizon/Containerfile?raw";
import buildEh from "../../bazzite-horizon/build_files/build-event-horizon.sh?raw";
import buildFinal from "../../bazzite-horizon/build_files/build.sh?raw";
import hyprland from "../../bazzite-horizon/system_files/usr/share/event-horizon/skel/hypr/hyprland.conf?raw";
import profile from "../../bazzite-horizon/profile.yaml?raw";
import readme from "../../bazzite-horizon/README.md?raw";

export type RecipeFile = {
  id: string;
  label: string;
  body: string;
};

export const recipeFiles: RecipeFile[] = [
  { id: "readme", label: "README", body: readme },
  { id: "containerfile", label: "Containerfile", body: containerfile },
  { id: "compile", label: "Compile", body: buildEh },
  { id: "image", label: "Image", body: buildFinal },
  { id: "hyprland", label: "Hyprland", body: hyprland },
  { id: "profile", label: "Profile", body: profile },
];

export const EH_REF = "696be1a855a2c682e15765a92cc189f1f8de84be";
