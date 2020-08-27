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

Dictionary HandEval::evaluate(String card1, String card2, String card3,
                              String card4, String card5, String card6,
                              String card7) {
  char* cards[] = {card1.alloc_c_string(), card2.alloc_c_string(),
                   card3.alloc_c_string(), card4.alloc_c_string(),
                   card5.alloc_c_string(), card6.alloc_c_string(),
                   card7.alloc_c_string()};

  auto rank = phevaluator::EvaluateCards(cards[0], cards[1], cards[2], cards[3],
                                         cards[4], cards[5], cards[6]);
  for (int i = 0; i < 7; i++) {
    godot::api->godot_free(cards[i]);
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
                           .replacen("J", 11)
                           .replacen("Q", 12)
                           .replacen("K", 13)
                           .replacen("A", 14);
  return Array(handValuesStr.split_ints(" ", false));
}
