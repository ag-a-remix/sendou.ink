import { LfgGroupType } from "@prisma/client";
import {
  ActionFunction,
  json,
  LinksFunction,
  LoaderFunction,
  MetaFunction,
  redirect,
  useLoaderData,
} from "remix";
import invariant from "tiny-invariant";
import { z } from "zod";
import { GroupCard } from "~/components/play/GroupCard";
import { LookingInfoText } from "~/components/play/LookingInfoText";
import { FinishedGroup } from "~/components/play/FinishedGroup";
import { Tab } from "~/components/Tab";
import { LFG_GROUP_FULL_SIZE } from "~/constants";
import {
  skillToMMR,
  teamHasSkill,
  teamSkillToApproximateMMR,
  teamSkillToExactMMR,
} from "~/core/mmr/utils";
import { groupExpiredDates, uniteGroupInfo } from "~/core/play/utils";
import { canUniteWithGroup, isGroupAdmin } from "~/core/play/validators";
import { usePolling } from "~/hooks/common";
import * as LFGGroup from "~/models/LFGGroup.server";
import styles from "~/styles/play-looking.css";
import {
  makeTitle,
  parseRequestFormData,
  requireUser,
  UserLean,
  validate,
} from "~/utils";
import { addInfoFromOldSendouInk } from "~/core/play/playerInfos/playerInfos.server";

export const links: LinksFunction = () => {
  return [{ rel: "stylesheet", href: styles }];
};

export const meta: MetaFunction = ({ data }: { data: LookingLoaderData }) => {
  return {
    title: makeTitle([
      `(${data.likedGroups.length}/${data.neutralGroups.length}/${data.likerGroups.length})`,
      "Looking",
    ]),
  };
};

export type LookingActionSchema = z.infer<typeof lookingActionSchema>;
const lookingActionSchema = z.union([
  z.object({
    _action: z.enum(["LIKE", "UNLIKE", "MATCH_UP"]),
    targetGroupId: z.string().uuid(),
  }),
  z.object({
    _action: z.literal("UNITE_GROUPS"),
    targetGroupId: z.string().uuid(),
    // we also get target number size so that when you like or try to unite groups
    // what you see on your screen will be guaranteed to match what the group
    // actually is
    targetGroupSize: z.preprocess(Number, z.number().min(1).max(4).int()),
  }),
  z.object({
    _action: z.literal("LOOK_AGAIN"),
  }),
  z.object({
    _action: z.literal("UNEXPIRE"),
  }),
]);

export const action: ActionFunction = async ({ request, context }) => {
  const data = await parseRequestFormData({
    request,
    schema: lookingActionSchema,
  });
  const user = requireUser(context);

  const ownGroup = await LFGGroup.findActiveByMember(user);
  validate(ownGroup, "No active group");
  validate(ownGroup.looking, "Group is not looking");
  validate(isGroupAdmin({ group: ownGroup, user }), "Not group admin");

  switch (data._action) {
    case "UNITE_GROUPS": {
      validate(
        canUniteWithGroup({
          ownGroupType: ownGroup.type,
          ownGroupSize: ownGroup.members.length,
          otherGroupSize: data.targetGroupSize,
        }),
        "Group to unite with too big"
      );

      const groupToUniteWith = await LFGGroup.findById(data.targetGroupId);
      // let's just fail silently if they already
      // matched up with someone else or stopped looking
      if (
        !groupToUniteWith ||
        groupToUniteWith.members.length !== data.targetGroupSize ||
        !groupToUniteWith.looking
      ) {
        break;
      }

      await LFGGroup.uniteGroups({
        ...uniteGroupInfo(
          {
            id: ownGroup.id,
            memberCount: ownGroup.members.length,
          },
          {
            id: groupToUniteWith.id,
            memberCount: groupToUniteWith.members.length,
          }
        ),
        unitedGroupIsRanked:
          // if one group is ranked and other is unranked
          // the new group should use the ranked status of
          // own group
          ownGroup.ranked === groupToUniteWith.ranked ||
          typeof ownGroup.ranked !== "boolean"
            ? undefined
            : ownGroup.ranked,
      });

      break;
    }
    case "MATCH_UP": {
      const groupToMatchUpWith = await LFGGroup.findById(data.targetGroupId);
      validate(groupToMatchUpWith, "Invalid targetGroupId");

      await LFGGroup.matchUp({
        groupIds: [ownGroup.id, data.targetGroupId],
        ranked: Boolean(groupToMatchUpWith.ranked && ownGroup.ranked),
      });
      break;
    }
    case "UNLIKE": {
      await LFGGroup.unlike({
        likerId: ownGroup.id,
        targetId: data.targetGroupId,
      });
      break;
    }
    case "LIKE": {
      await LFGGroup.like({
        likerId: ownGroup.id,
        targetId: data.targetGroupId,
      });
      break;
    }
    case "LOOK_AGAIN": {
      await LFGGroup.setInactive(ownGroup.id);
      return redirect("/play");
    }
    case "UNEXPIRE": {
      await LFGGroup.unexpire(ownGroup.id);
      break;
    }
    default: {
      const exhaustive: never = data;
      throw new Response(`Unknown action: ${JSON.stringify(exhaustive)}`, {
        status: 400,
      });
    }
  }

  return { ok: data._action };

  // TODO: notify watchers
};

export type LookingLoaderDataGroup = {
  id: string;
  members?: (UserLean & {
    MMR?: number;
    weapons?: string[];
    peakXP?: number;
    peakLP?: number;
  })[];
  teamMMR?: {
    exact: boolean;
    value: number;
  };
  ranked?: boolean;
};

export interface LookingLoaderData {
  likedGroups: LookingLoaderDataGroup[];
  neutralGroups: LookingLoaderDataGroup[];
  likerGroups: LookingLoaderDataGroup[];
  ownGroup: LookingLoaderDataGroup;
  type: LfgGroupType;
  isCaptain: boolean;
  lastActionAtTimestamp: number;
}

export const loader: LoaderFunction = async ({ context }) => {
  const user = requireUser(context);
  const groups = await LFGGroup.findLooking();

  const ownGroup = groups.find((g) =>
    g.members.some((m) => m.user.id === user.id)
  );

  if (!ownGroup) return redirect("/play");
  if (ownGroup.matchId) return redirect(`/play/match/${ownGroup.matchId}`);
  if (!ownGroup.looking) return redirect("/play/add-players");

  const lookingForMatch =
    ownGroup.type === "VERSUS" &&
    ownGroup.members.length === LFG_GROUP_FULL_SIZE;

  const groupsOfType = groups.filter((g) => g.type === ownGroup.type);

  const likesGiven = ownGroup.likedGroups.reduce(
    (acc, lg) => acc.add(lg.targetId),
    new Set<string>()
  );
  const likesReceived = ownGroup.likesReceived.reduce(
    (acc, lg) => acc.add(lg.likerId),
    new Set<string>()
  );

  const isRanked = groupsOfType.some((g) => g.ranked);
  const ownGroupWithMembers = groupsOfType.find((g) => g.id === ownGroup.id);
  invariant(ownGroupWithMembers, "ownGroupWithMembers is undefined");
  const ownGroupForResponse: LookingLoaderDataGroup = {
    id: ownGroup.id,
    members: ownGroupWithMembers.members.map((m) => {
      const { skill, ...rest } = m.user;

      return {
        ...rest,
        MMR: lookingForMatch && ownGroup.ranked ? undefined : skillToMMR(skill),
      };
    }),
    ranked: ownGroup.ranked ?? undefined,
    teamMMR:
      lookingForMatch && isRanked && teamHasSkill(ownGroupWithMembers.members)
        ? {
            exact: true,
            value: teamSkillToExactMMR(ownGroupWithMembers.members),
          }
        : undefined,
  };

  const { EXPIRED: expiredDate } = groupExpiredDates();

  return json<LookingLoaderData>(
    addInfoFromOldSendouInk(
      ownGroup.type === "VERSUS" ? "SOLO" : "LEAGUE",
      !lookingForMatch,
      {
        ownGroup: ownGroupForResponse,
        type: ownGroup.type,
        isCaptain: isGroupAdmin({ group: ownGroup, user }),
        lastActionAtTimestamp: ownGroup.lastActionAt.getTime(),
        ...groupsOfType
          .filter(
            (group) =>
              (lookingForMatch &&
                group.members.length === LFG_GROUP_FULL_SIZE) ||
              canUniteWithGroup({
                ownGroupType: ownGroup.type,
                ownGroupSize: ownGroup.members.length,
                otherGroupSize: group.members.length,
              })
          )
          .filter((group) => group.id !== ownGroup.id)
          .filter(
            (group) => group.lastActionAt.getTime() > expiredDate.getTime()
          )
          .map((group) => {
            const ranked = () => {
              if (lookingForMatch && !ownGroup.ranked) return false;

              return group.ranked ?? undefined;
            };
            return {
              id: group.id,
              // When looking for a match ranked groups are censored
              // and instead we only reveal their approximate skill level
              members:
                ownGroup.ranked && group.ranked && lookingForMatch
                  ? undefined
                  : group.members.map((m) => {
                      const { skill, ...rest } = m.user;

                      return {
                        ...rest,
                        MMR: skillToMMR(skill),
                      };
                    }),
              ranked: ranked(),
              teamMMR:
                lookingForMatch && group.ranked && teamHasSkill(group.members)
                  ? {
                      exact: false,
                      value: teamSkillToApproximateMMR(group.members),
                    }
                  : undefined,
            };
          })
          .reduce(
            (
              acc: Omit<
                LookingLoaderData,
                "ownGroup" | "type" | "isCaptain" | "lastActionAtTimestamp"
              >,
              group
            ) => {
              // likesReceived first so that if both received like and
              // given like then handle this edge case by just displaying the
              // group as waiting like back
              if (likesReceived.has(group.id)) {
                acc.likerGroups.push(group);
              } else if (likesGiven.has(group.id)) {
                acc.likedGroups.push(group);
              } else {
                acc.neutralGroups.push(group);
              }
              return acc;
            },
            { likedGroups: [], neutralGroups: [], likerGroups: [] }
          ),
      }
    )
  );
};

export default function LookingPage() {
  const data = useLoaderData<LookingLoaderData>();

  const isPolling = !lookingOver(data.type, data.ownGroup);
  const lastUpdated = usePolling(isPolling);

  if (lookingOver(data.type, data.ownGroup)) {
    return <FinishedGroup />;
  }

  const lookingForMatch = data.ownGroup.members?.length === LFG_GROUP_FULL_SIZE;

  const columns = [
    { type: "LIKES_GIVEN", groups: data.likedGroups, title: "Liked" },
    { type: "NEUTRAL", groups: data.neutralGroups, title: "Neutral" },
    {
      type: "LIKES_RECEIVED",
      groups: data.likerGroups,
      title: lookingForMatch ? "Match up" : "Group up",
    },
  ] as const;

  return (
    <div className="container">
      <GroupCard
        group={data.ownGroup}
        ranked={data.ownGroup.ranked}
        lookingForMatch={false}
        isOwnGroup
        isCaptain={data.isCaptain}
      />
      <LookingInfoText lastUpdated={lastUpdated} />
      <hr className="play-looking__divider" />
      <Tab
        containerClassName="play-looking__tabs"
        tabListClassName="play-looking__tab-list"
        defaultIndex={1}
        tabs={columns.map((column) => ({
          id: column.type,
          title: column.title,
          content: (
            <div className="play-looking__cards">
              {column.groups.map((group) => {
                return (
                  <GroupCard
                    key={group.id}
                    group={group}
                    isCaptain={data.isCaptain}
                    type={column.type}
                    ranked={
                      column.type === "LIKES_RECEIVED" && !lookingForMatch
                        ? data.ownGroup.ranked
                        : group.ranked
                    }
                    lookingForMatch={lookingForMatch}
                  />
                );
              })}
            </div>
          ),
        }))}
      />
      <div className="play-looking__columns">
        {columns.map((column) => (
          <div key={column.type}>
            <h2 className="play-looking__column-header">{column.title}</h2>
            <div className="play-looking__cards">
              {column.groups.map((group) => {
                return (
                  <GroupCard
                    key={group.id}
                    group={group}
                    isCaptain={data.isCaptain}
                    type={column.type}
                    ranked={
                      column.type === "LIKES_RECEIVED" && !lookingForMatch
                        ? data.ownGroup.ranked
                        : group.ranked
                    }
                    lookingForMatch={lookingForMatch}
                  />
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function lookingOver(type: LfgGroupType, ownGroup: LookingLoaderDataGroup) {
  if (type === "TWIN" && ownGroup.members?.length === 2) {
    return true;
  }

  if (["QUAD"].includes(type) && ownGroup.members?.length === 4) {
    return true;
  }

  return false;
}
