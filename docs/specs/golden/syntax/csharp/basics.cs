// Conformance case for the C# syntax extractor (plugin-interface.md, sections 3 to 5).
using System;
using System.Collections.Generic;

namespace Shop.Core;

/// <summary>An order.</summary>
public partial class Order : IPrintable
{
    public const int MaxItems = 50;
    private readonly List<string> _items = new List<string>();
    public event EventHandler Changed;
    public string Id { get; init; } = "";
    public string this[int index] => _items[index];

    public Order() { }
    static Order() { }
    ~Order() { }

    /// <summary>Adds an item.</summary>
    public bool Add(string item)
    {
        if (item.Length == 0 || _items.Count >= MaxItems)
        {
            return false;
        }
        _items.Add(item);
        Changed.Invoke(this, EventArgs.Empty);
        return true;
    }

    public bool Add(string item, int quantity)
    {
        for (var i = 0; i < quantity; i++)
        {
            Add(item);
        }
        return true;
    }

    public T Get<T>(int index) => (T)(object)_items[index];

    public static explicit operator string(Order order) => order.Id;

    void IPrintable.Print() => Console.WriteLine(Id);

    public enum State { Draft, Placed }
}

public interface IPrintable { void Print(); }

public record Customer(string Name, int Age);

public delegate void Notify(Order order);
