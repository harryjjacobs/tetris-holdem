#include "handeval.h"

#include <phevaluator/phevaluator.h>

using namespace godot;

void HandEval::_register_methods() {
  register_method("evaluate", &HandEval::evaluate);
}

HandEval::HandEval() {}

HandEval::~HandEval() {
  // add your cleanup here
}

void HandEval::_init() {}

Dictionary HandEval::evaluate(Array cards) {
  char* cards_str[7];

  for (godot_int i = 0; i < cards.size(); i++) {
    String card = cards[i];
    cards_str[i] = card.alloc_c_string();
  }

  phevaluator::Rank rank;

  if (cards.size() == 6) {
    rank = phevaluator::EvaluateCards(cards_str[0], cards_str[1], cards_str[2],
                                      cards_str[3], cards_str[4], cards_str[5]);
  } else if (cards.size() == 7) {
    rank = phevaluator::EvaluateCards(cards_str[0], cards_str[1], cards_str[2],
                                      cards_str[3], cards_str[4], cards_str[5],
                                      cards_str[6]);
  } else {
    return Dictionary();
  }

  for (godot_int i = 0; i < cards.size(); i++) {
    godot::api->godot_free(cards_str[i]);
  }

  auto category = (int)rank.category();
  auto handValues = hand_description_to_ranks(rank.describeSampleHand());
  handValues.sort();

  if (category == STRAIGHT_FLUSH) {
    if ((int)handValues[0] == 10) {
      category = 0;  // best hand: royal straight flush
    }
  }

  auto result = Dictionary::make(String("category"), category, String("hand"),
                                 handValues);
  return result;
}

Array HandEval::hand_description_to_ranks(const std::string& desc) const {
  auto handValuesStr = String(desc.c_str())
                           .replacen("T", "10")
                           .replacen("J", "11")
                           .replacen("Q", "12")
                           .replacen("K", "13")
                           .replacen("A", "14");
  return Array(handValuesStr.split_ints(" ", false));
}
