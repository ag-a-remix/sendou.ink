const { UserInputError, gql } = require("apollo-server-express")
const Tournament = require("../models/tournament")
const Round = require("../models/round")
const mongoose = require("mongoose")

const typeDef = gql`
  extend type Query {
    searchForTournamentById(id: String!): Tournament
    searchForTournaments(
      tournament_name: String
      jpn: Boolean
      player_name: String
      unique_id: String
      team_name: String
      comp: [String]
      page: Int
    ): TournamentCollection!
  }
  type Tournament {
    name: String!
    bracket: String
    "True if the tournament was a Japanese one"
    jpn: Boolean!
    "Link to the Google Sheet containing ganbawoomy's data"
    google_sheet_url: String
    date: String!
    "Top 5 of the most played weapons in the rounds recorded"
    popular_weapons: [String!]!
    winning_team_name: String!
    winning_team_players: [String!]!
    winning_team_unique_ids: [String]
    rounds: [Round!]!
  }
  type TournamentCollection {
    tournaments: [Tournament]!
    pageCount: Int!
  }
  type Round {
    tournament_id: Tournament!
    stage: String!
    "SZ/TC/RM/CB/TW"
    mode: Mode!
    "E.g. Quarter-Finals"
    round_name: String!
    "Order of the round. Smaller number means the round took place before."
    round_number: Int!
    "Order the match in the round. Smaller number means the match took place before."
    game_number: Int!
    winning_team_name: String!
    winning_team_players: [String!]!
    winning_team_unique_ids: [String]!
    winning_team_weapons: [String!]!
    winning_team_main_abilities: [[Ability]!]!
    winning_team_sub_abilities: [[Ability]!]!
    losing_team_name: String!
    losing_team_players: [String!]!
    losing_team_unique_ids: [String]!
    losing_team_weapons: [String!]!
    losing_team_main_abilities: [[Ability]!]!
    losing_team_sub_abilities: [[Ability]!]!
  }
  enum Mode {
    SZ
    TC
    RM
    CB
    TW
  }
`

const resolvers = {
  Query: {
    searchForTournamentById: async (root, args) => {
      if (!args.id.match(/^[0-9a-fA-F]{24}$/)) return null
      const rounds = await Round.find({ tournament_id: args.id })
        .sort({ round_number: "asc", game_number: "asc" })
        .catch(e => {
          throw new UserInputError(e.message, {
            invalidArgs: args
          })
        })

      const tournament = await Tournament.findById(args.id).catch(e => {
        throw new UserInputError(e.message, {
          invalidArgs: args
        })
      })

      if (!tournament) return null
      tournament.rounds = rounds
      return tournament
    },
    searchForTournaments: async (root, args) => {
      const tournamentsPerPage = 20
      const currentPage = args.page ? args.page - 1 : 0

      const roundSearchCriteria = {
        $or: []
      }

      if (args.team_name) {
        roundSearchCriteria.$or.push({
          winning_team_name: {
            $regex: args.team_name,
            $options: "i"
          }
        })
        roundSearchCriteria.$or.push({
          losing_team_name: {
            $regex: args.team_name,
            $options: "i"
          }
        })
      }

      if (args.player_name) {
        roundSearchCriteria.$or.push({
          winning_team_players: {
            $regex: args.player_name,
            $options: "i"
          }
        })
        roundSearchCriteria.$or.push({
          losing_team_players: {
            $regex: args.player_name,
            $options: "i"
          }
        })
      }

      if (args.unique_id) {
        roundSearchCriteria.$or.push({
          winning_team_unique_ids: {
            $regex: args.unique_id,
            $options: "i"
          }
        })
        roundSearchCriteria.$or.push({
          losing_team_unique_ids: {
            $regex: args.unique_id,
            $options: "i"
          }
        })
      }

      if (args.comp) {
        roundSearchCriteria.$or.push({
          winning_team_weapons: {
            $all: args.comp
          }
        })

        roundSearchCriteria.$or.push({
          losing_team_weapons: {
            $all: args.comp
          }
        })
      }

      // if criteria were presented that we have to search
      // from the Round collection
      let tournament_ids = null
      const tournamentSearchCriteria = {}
      if (roundSearchCriteria.$or.length !== 0) {
        tournament_ids = await Round.find(roundSearchCriteria).distinct(
          "tournament_id"
        )

        tournamentSearchCriteria._id = {
          $in: tournament_ids
        }
      }

      if (args.tournament_name)
        tournamentSearchCriteria.name = {
          $regex: args.tournament_name,
          $options: "i"
        }
      if (args.hasOwnProperty("jpn")) tournamentSearchCriteria.jpn = args.jpn

      const tournamentCount = await Tournament.countDocuments(
        tournamentSearchCriteria
      ).catch(e => {
        throw new UserInputError(e.message, {
          invalidArgs: args
        })
      })

      const pageCount = Math.ceil(tournamentCount / tournamentsPerPage)
      // if 0 documents we don't care if the page is wrong
      if (tournamentCount !== 0) {
        if (args.page > pageCount)
          throw new UserInputError("too big page number given", {
            invalidArgs: args
          })
      }

      const tournaments = await Tournament.find(tournamentSearchCriteria)
        .skip(tournamentsPerPage * currentPage)
        .limit(tournamentsPerPage)
        .sort({ date: "desc" })
        .catch(e => {
          throw new UserInputError(e.message, {
            invalidArgs: args
          })
        })

      return { tournaments, pageCount }
    }
  }
}

module.exports = {
  Tournament: typeDef,
  tournamentResolvers: resolvers
}
