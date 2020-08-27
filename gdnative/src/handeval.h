#ifndef HANDEVAL_H
#define HANDEVAL_H

#include <Godot.hpp>

namespace godot {

class HandEval : public Reference {
  GODOT_CLASS(HandEval, Reference)

 private:
  float time_passed;

 public:
  static void _register_methods();

  HandEval();
  ~HandEval();

  Dictionary evaluate(String card1, String card2, String card3, String card4,
                      String card5, String card6, String card7);
  Array hand_description_to_ranks(const std::string& desc) const;
};

extern "C" void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options* o) {
  Godot::gdnative_init(o);
}

extern "C" void GDN_EXPORT
godot_gdnative_terminate(godot_gdnative_terminate_options* o) {
  Godot::gdnative_terminate(o);
}

extern "C" void GDN_EXPORT godot_nativescript_init(void* handle) {
  Godot::nativescript_init(handle);
  register_class<HandEval>();
}

}  // namespace godot

#endif