import type {
  LookingLoaderData,
  LookingLoaderDataGroup,
} from "~/routes/play/looking";
import rawInfos from "./data.json";

const infos = rawInfos as Partial<
  Record<string, { weapons?: string[]; peakXP?: number; peakLP?: number }>
>;

export function addInfoFromOldSendouInk(
  type: "LEAGUE" | "SOLO",
  showWeapons: boolean,
  data: LookingLoaderData
): LookingLoaderData {
  return {
    ...data,
    ownGroup: mapGroup(data.ownGroup),
    likedGroups: data.likedGroups.map(mapGroup),
    neutralGroups: data.neutralGroups.map(mapGroup),
    likerGroups: data.likerGroups.map(mapGroup),
  };

  function mapGroup(group: LookingLoaderDataGroup): LookingLoaderDataGroup {
    return {
      ...group,
      members: group.members?.map((member) => {
        const playerInfos = infos[member.discordId];
        return {
          ...member,
          weapons: showWeapons ? playerInfos?.weapons?.slice(0, 3) : undefined,
          peakXP: type === "SOLO" ? playerInfos?.peakXP : undefined,
          peakLP: type === "LEAGUE" ? playerInfos?.peakLP : undefined,
        };
      }),
    };
  }
}
