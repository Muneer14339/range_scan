import 'package:flutter/material.dart';

class AppDropdown<T> extends StatefulWidget {
  final String label;
  final bool isRequired;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?)? onChanged;
  final String? hintText;
  final bool enabled;

  // Loading
  final bool isLoading;

  // Button
  final bool showButton;
  final String buttonText;
  final VoidCallback? onButtonTap;

  // Search
  final bool showSearch;

  const AppDropdown({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.isLoading = false,
    this.showButton = false,
    this.buttonText = "Add New",
    this.onButtonTap,
    this.showSearch = false,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  String _searchQuery = '';

  void _showCustomDropdown(BuildContext context) async {
    if (widget.isLoading) return; // prevent opening while loading

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final result = await showMenu<T>(
      context: context,
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 6,
        position.dx + size.width,
        0,
      ),
      constraints: BoxConstraints(
        maxWidth: size.width,
        minWidth: size.width,
        maxHeight: widget.items.isEmpty
            ? 150
            : (widget.items.length > 5 ? 300 : widget.items.length * 60),
      ),
      items: [
        PopupMenuItem<T>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setState) {
              final filteredItems = widget.showSearch
                  ? widget.items
                      .where((e) => widget
                          .itemLabel(e)
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList()
                  : widget.items;

              return SizedBox(
                height: widget.items.isEmpty
                    ? 150
                    : (widget.items.length > 5 ? 300 : widget.items.length * 60),
                child: Column(
                  children: [
                    // 🔍 Search Bar
                    if (widget.showSearch)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: "Search...",
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.6)),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white70),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),

                    // 📋 Items list
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                "No items found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final e = filteredItems[index];
                                return InkWell(
                                  onTap: () => Navigator.pop(context, e),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Text(
                                      widget.itemLabel(e),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // ➕ Add New button
                    if (widget.showButton)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            top: BorderSide(
                                color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onButtonTap?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFff6b35), width: 2),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (result != null && widget.onChanged != null) {
      widget.onChanged!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue =
        widget.value != null && widget.items.contains(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏷️ Label
        Text(
          widget.label + (widget.isRequired ? ' *' : ''),
          style: const TextStyle(
            color: Color(0xFFff6b35),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),

        // 🔽 Dropdown
        GestureDetector(
          onTap: widget.enabled ? () => _showCustomDropdown(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text
                Expanded(
                  child: Text(
                    hasValue
                        ? widget.itemLabel(widget.value as T)
                        : (widget.hintText ?? 'Select'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),

                // ⏳ Replace dropdown icon with loading spinner
                widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.arrow_drop_down,
                        color: widget.enabled
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
