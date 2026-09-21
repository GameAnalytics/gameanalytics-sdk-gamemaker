/// @description Clean up on game exit
ga_http_abort();
ga_on_quit();
show_debug_message("[GA Sample] Game end — ga_on_quit() called.");
